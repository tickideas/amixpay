const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const config = require('../config');
const User = require('../db/models/User');
const db = require('../db/knex');
const { redisSet, redisDel, redisExists } = require('../redis/client');
const ApiError = require('../utils/ApiError');

const BCRYPT_ROUNDS = 12;
const pendingTotpSecrets = new Map(); // temp storage for TOTP setup

// ─── Password ────────────────────────────────────────────────────────────────

function validatePasswordStrength(password) {
  if (!password || password.length < 8) throw ApiError.badRequest('Password must be at least 8 characters');
}

// ─── Tokens ──────────────────────────────────────────────────────────────────

function generateAccessToken(user) {
  return jwt.sign(
    { sub: user.id, userId: user.id, email: user.email, role: user.role, jti: uuidv4() },
    config.jwt.secret,
    { expiresIn: config.jwt.accessExpiresIn || '15m' }
  );
}

async function generateRefreshToken(userId) {
  const token = crypto.randomBytes(40).toString('hex');
  const ttl = 30 * 24 * 60 * 60; // 30 days in seconds
  await redisSet(`refresh:${token}`, userId, ttl);
  return token;
}

function parseExpiry(str) {
  const match = String(str || '7d').match(/^(\d+)([smhd])$/);
  if (!match) return 7 * 24 * 3600;
  const n = parseInt(match[1]);
  return match[2] === 's' ? n : match[2] === 'm' ? n * 60 : match[2] === 'h' ? n * 3600 : n * 86400;
}

function buildTokenResponse(user) {
  return {
    access_token: generateAccessToken(user),
    expires_in: parseExpiry(config.jwt.accessExpiresIn),
    token_type: 'Bearer',
  };
}

// ─── Registration ─────────────────────────────────────────────────────────────

async function register({ email, password, firstName, lastName, username, phone, countryCode, dateOfBirth }) {
  if (!email || !password || !firstName || !lastName || !username) {
    throw ApiError.badRequest('Missing required fields');
  }

  validatePasswordStrength(password);

  const existingEmail = await User.findByEmail(email);
  if (existingEmail) throw ApiError.conflict('Email already registered');

  const existingUsername = await User.findByUsername(username);
  if (existingUsername) throw ApiError.conflict('Username already taken');

  const password_hash = await bcrypt.hash(password, BCRYPT_ROUNDS);

  const user = await User.create({
    username: username.toLowerCase(),
    email: email.toLowerCase(),
    password_hash,
    first_name: firstName,
    last_name: lastName,
    phone: phone || null,
    country_code: countryCode || null,
    date_of_birth: dateOfBirth || null,
    status: 'active',
    role: 'user',
  });

  const tokens = buildTokenResponse(user);
  const refreshToken = await generateRefreshToken(user.id);
  await User.update(user.id, { last_login_at: new Date() });

  return { user: User.safeFields(user), ...tokens, refresh_token: refreshToken };
}

// ─── Login ────────────────────────────────────────────────────────────────────

async function login(email, password) {
  const user = await User.findByEmail(email);
  if (!user) throw ApiError.unauthorized('Invalid credentials');

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) throw ApiError.unauthorized('Invalid credentials');

  if (user.status === 'suspended') throw ApiError.forbidden('Account suspended. Contact support.');

  if (user.two_factor_on) {
    const challengeToken = jwt.sign(
      { sub: user.id, purpose: '2fa_challenge' },
      config.jwt.secret,
      { expiresIn: '5m' }
    );
    return { requires_2fa: true, challenge_token: challengeToken };
  }

  await User.update(user.id, { last_login_at: new Date() });
  const tokens = buildTokenResponse(user);
  const refreshToken = await generateRefreshToken(user.id);

  return { user: User.safeFields(user), ...tokens, refresh_token: refreshToken };
}

// ─── Token Refresh ────────────────────────────────────────────────────────────

async function refreshToken(token) {
  const userId = await (async () => {
    try {
      const { getClient } = require('../redis/client');
      const c = await getClient();
      return c.get(`refresh:${token}`);
    } catch { return null; }
  })();

  if (!userId) throw ApiError.unauthorized('Invalid or expired refresh token');

  // Rotate refresh token
  await redisDel(`refresh:${token}`);
  const user = await User.findById(userId);
  if (!user) throw ApiError.unauthorized('User not found');

  const newTokens = buildTokenResponse(user);
  const newRefresh = await generateRefreshToken(user.id);
  return { ...newTokens, refresh_token: newRefresh };
}

// ─── Logout ───────────────────────────────────────────────────────────────────

async function logout(userId, accessToken, refreshToken) {
  // Blacklist access token until its natural expiry (15 min)
  if (accessToken) {
    await redisSet(`blacklist:${accessToken}`, '1', 900);
  }
  // Invalidate refresh token
  if (refreshToken) {
    try {
      const { getClient } = require('../redis/client');
      const c = await getClient();
      // Find and delete all user's refresh tokens (simplified: just delete this one)
      await c.del(`refresh:${refreshToken}`);
    } catch (_) {}
  }
}

// ─── 2FA / TOTP ───────────────────────────────────────────────────────────────

async function enableTotp(userId) {
  const user = await User.findById(userId);
  if (!user) throw ApiError.notFound('User not found');
  if (user.two_factor_on) throw ApiError.badRequest('2FA is already enabled');

  const secret = speakeasy.generateSecret({
    name: `AmixPay:${user.email}`,
    issuer: 'AmixPay',
    length: 20,
  });

  pendingTotpSecrets.set(userId, secret.base32);
  const qrDataUrl = await QRCode.toDataURL(secret.otpauth_url);

  return { secret: secret.base32, qrDataUrl, otpauthUrl: secret.otpauth_url };
}

async function verifyAndActivateTotp(userId, code) {
  const secret = pendingTotpSecrets.get(userId);
  if (!secret) throw ApiError.badRequest('2FA setup not initiated. Call /auth/2fa/enable first.');

  const valid = speakeasy.totp.verify({ secret, encoding: 'base32', token: code, window: 1 });
  if (!valid) throw ApiError.badRequest('Invalid verification code');

  // Generate backup codes
  const backupCodes = Array.from({ length: 10 }, () => crypto.randomBytes(4).toString('hex').toUpperCase());

  await db('two_factor_auth')
    .insert({
      user_id: userId,
      method: 'totp',
      secret_encrypted: secret, // In prod: encrypt with KMS
      backup_codes_enc: JSON.stringify(backupCodes),
      enabled_at: new Date(),
    })
    .onConflict('user_id')
    .merge({ secret_encrypted: secret, backup_codes_enc: JSON.stringify(backupCodes), enabled_at: new Date() });

  await User.update(userId, { two_factor_on: true });
  pendingTotpSecrets.delete(userId);

  return { enabled: true, backupCodes };
}

async function verifyTotpChallenge(challengeToken, code) {
  let payload;
  try {
    payload = jwt.verify(challengeToken, config.jwt.secret);
  } catch {
    throw ApiError.unauthorized('Invalid or expired challenge token');
  }

  if (payload.purpose !== '2fa_challenge') throw ApiError.badRequest('Invalid challenge token');

  const tfa = await db('two_factor_auth').where({ user_id: payload.sub }).first();
  if (!tfa) throw ApiError.badRequest('2FA not configured');

  // Check backup code
  const backupCodes = JSON.parse(tfa.backup_codes_enc || '[]');
  const isBackupCode = backupCodes.includes(code.toUpperCase());

  if (isBackupCode) {
    // Burn the backup code
    const remaining = backupCodes.filter((c) => c !== code.toUpperCase());
    await db('two_factor_auth').where({ user_id: payload.sub }).update({ backup_codes_enc: JSON.stringify(remaining) });
  } else {
    const valid = speakeasy.totp.verify({ secret: tfa.secret_encrypted, encoding: 'base32', token: code, window: 1 });
    if (!valid) throw ApiError.unauthorized('Invalid 2FA code');
  }

  const user = await User.findById(payload.sub);
  if (!user) throw ApiError.unauthorized('User not found');

  await User.update(user.id, { last_login_at: new Date() });
  const tokens = buildTokenResponse(user);
  const refreshToken = await generateRefreshToken(user.id);

  return { user: User.safeFields(user), ...tokens, refresh_token: refreshToken };
}

async function disableTotp(userId, password) {
  const user = await User.findById(userId);
  if (!user) throw ApiError.notFound('User not found');

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) throw ApiError.badRequest('Incorrect password');

  await db('two_factor_auth').where({ user_id: userId }).delete();
  await User.update(userId, { two_factor_on: false });
  return { disabled: true };
}

module.exports = {
  register, login, refreshToken, logout,
  enableTotp, verifyAndActivateTotp, verifyTotpChallenge, disableTotp,
};
