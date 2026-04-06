const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const authService = require('../services/authService');
const { authenticate } = require('../middleware/authenticate');
const { authLimiter } = require('../middleware/rateLimiter');
const walletService = require('../services/walletService');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');
const { redisSet, redisGet, redisDel } = require('../redis/client');
const User = require('../db/models/User');
const config = require('../config');
const emailService = require('../services/emailService');

// Country code → default wallet currency
const COUNTRY_CURRENCY = {
  US: 'USD', CA: 'CAD', GB: 'GBP', AU: 'AUD', NZ: 'NZD',
  NG: 'NGN', KE: 'KES', GH: 'GHS', ZA: 'ZAR', UG: 'UGX', TZ: 'TZS',
  DE: 'EUR', FR: 'EUR', ES: 'EUR', IT: 'EUR', NL: 'EUR', BE: 'EUR',
  AT: 'EUR', PT: 'EUR', FI: 'EUR', IE: 'EUR', GR: 'EUR', LU: 'EUR',
  JP: 'JPY', CN: 'CNY', CH: 'CHF', SE: 'SEK', NO: 'NOK', DK: 'DKK',
  SG: 'SGD', HK: 'HKD', IN: 'INR', BR: 'BRL', MX: 'MXN',
};

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

const router = Router();

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  }
  next();
};

// POST /v1/auth/register
router.post('/register',
  authLimiter,
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    body('firstName').trim().notEmpty(),
    body('lastName').trim().notEmpty(),
    body('username').trim().isLength({ min: 3, max: 30 }).matches(/^[a-zA-Z0-9_.]+$/),
    body('phone').optional({ checkFalsy: true }).trim(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { email, password, firstName, lastName, username, phone, countryCode, dateOfBirth } = req.body;
      const result = await authService.register({
        email, password, firstName, lastName, username, phone, countryCode, dateOfBirth,
      });

      // Auto-create wallet with country-appropriate currency
      const walletCurrency = COUNTRY_CURRENCY[countryCode] || 'USD';
      await walletService.getOrCreateWallet(result.user.id, walletCurrency).catch(() => {});

      // Send email verification OTP (fire-and-forget — don't block registration)
      const otp = generateOtp();
      redisSet(`email_otp:${result.user.id}`, otp, 1800).catch(() => {}); // 30 min TTL
      emailService.sendVerificationCode({
        toEmail: email,
        firstName: result.user.first_name || firstName,
        code: otp,
      }).then(() => {
        console.log(`[Auth] Verification email sent to ${email}`);
      }).catch((err) => {
        // Always log the OTP so it's visible in Railway logs if email fails
        console.log(`[Auth] Verification OTP for ${email}: ${otp} (email failed: ${err.message})`);
      });

      res.status(201).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/login
router.post('/login',
  authLimiter,
  [body('email').isEmail().normalizeEmail(), body('password').notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const { email, password } = req.body;
      const result = await authService.login(email, password);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/refresh
router.post('/refresh',
  [body('refreshToken').notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const result = await authService.refreshToken(req.body.refreshToken);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/logout
router.post('/logout', authenticate, async (req, res, next) => {
  try {
    const refreshToken = req.body.refreshToken;
    await authService.logout(req.user.id, req.token, refreshToken);
    success(res, { message: 'Logged out successfully' });
  } catch (err) {
    next(err);
  }
});

// POST /v1/auth/forgot-password
router.post('/forgot-password',
  authLimiter,
  [body('email').isEmail().normalizeEmail()],
  validate,
  async (req, res, next) => {
    try {
      const { email } = req.body;
      const user = await User.findByEmail(email);

      if (user) {
        // Generate secure reset token valid for 1 hour
        const token = crypto.randomBytes(32).toString('hex');
        await redisSet(`pwd_reset:${token}`, user.id, 3600);

        // Build reset link — deep links into the app
        const resetLink = `${config.frontendUrl}?token=${token}&email=${encodeURIComponent(email)}`;

        try {
          await emailService.sendPasswordReset({ toEmail: email, firstName: user.first_name, resetLink });
        } catch (emailErr) {
          // Log the link if email fails (useful during dev/staging)
          console.log(`[PasswordReset] Reset link for ${email}: ${resetLink}`);
        }
      }

      // Always respond with success to prevent email enumeration
      success(res, { message: 'If that email exists, a reset link has been sent.' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/reset-password
router.post('/reset-password',
  [
    body('token').notEmpty(),
    body('email').isEmail().normalizeEmail(),
    body('newPassword').isLength({ min: 8 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { token, email, newPassword } = req.body;

      const userId = await redisGet(`pwd_reset:${token}`);
      if (!userId) throw ApiError.badRequest('Reset link has expired or is invalid. Please request a new one.');

      const user = await User.findByEmail(email);
      if (!user || user.id !== userId) throw ApiError.badRequest('Invalid reset request.');

      const password_hash = await bcrypt.hash(newPassword, 12);
      await User.update(userId, { password_hash });
      await redisDel(`pwd_reset:${token}`);

      success(res, { message: 'Password reset successful. Please log in.' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/verify-email  (requires auth token — user just registered)
router.post('/verify-email',
  authenticate,
  [body('code').notEmpty().isLength({ min: 6, max: 6 })],
  validate,
  async (req, res, next) => {
    try {
      const { code } = req.body;
      const stored = await redisGet(`email_otp:${req.user.id}`);
      if (!stored || stored !== code) {
        throw ApiError.badRequest('Invalid or expired verification code');
      }
      await User.update(req.user.id, { email_verified: true });
      await redisDel(`email_otp:${req.user.id}`);
      success(res, { message: 'Email verified successfully' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/resend-verification
router.post('/resend-verification',
  authLimiter,
  [body('email').isEmail().normalizeEmail()],
  validate,
  async (req, res, next) => {
    try {
      const user = await User.findByEmail(req.body.email);
      if (user && !user.email_verified) {
        const otp = generateOtp();
        await redisSet(`email_otp:${user.id}`, otp, 1800);
        emailService.sendVerificationCode({
          toEmail: user.email,
          firstName: user.first_name,
          code: otp,
        }).catch((err) => {
          console.log(`[Auth] Resend OTP for ${user.email}: ${otp} (email failed: ${err.message})`);
        });
      }
      // Always return success to prevent email enumeration
      success(res, { message: 'If that email exists, a new code has been sent.' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/send-phone-otp — send a verification code to the user's phone
router.post('/send-phone-otp',
  authLimiter,
  authenticate,
  async (req, res, next) => {
    try {
      const user = req.user;
      if (!user.phone) throw ApiError.badRequest('No phone number on file. Update your profile first.');
      if (user.phone_verified) throw ApiError.badRequest('Phone is already verified.');

      const otp = generateOtp();
      await redisSet(`phone_otp:${user.id}`, otp, 600); // 10 min TTL

      // TODO: Send OTP via Twilio SMS when TWILIO_ACCOUNT_SID is configured
      // For now, log the code (visible in Railway logs for dev/staging)
      console.log(`[Auth] Phone OTP for ${user.phone}: ${otp}`);

      success(res, { message: 'Verification code sent to your phone number.' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/verify-phone — verify phone with OTP code
router.post('/verify-phone',
  authenticate,
  [body('code').notEmpty().isLength({ min: 6, max: 6 })],
  validate,
  async (req, res, next) => {
    try {
      const { code } = req.body;
      const stored = await redisGet(`phone_otp:${req.user.id}`);
      if (!stored || stored !== code) {
        throw ApiError.badRequest('Invalid or expired verification code');
      }
      await User.update(req.user.id, { phone_verified: true, kyc_level: Math.max(req.user.kyc_level, 1) });
      await redisDel(`phone_otp:${req.user.id}`);
      success(res, { message: 'Phone verified successfully' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/2fa/enable
router.post('/2fa/enable', authenticate, async (req, res, next) => {
  try {
    const result = await authService.enableTotp(req.user.id);
    success(res, result);
  } catch (err) {
    next(err);
  }
});

// POST /v1/auth/2fa/verify
router.post('/2fa/verify', authenticate,
  [body('code').isLength({ min: 6, max: 6 })],
  validate,
  async (req, res, next) => {
    try {
      const result = await authService.verifyAndActivateTotp(req.user.id, req.body.code);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/2fa/disable
router.post('/2fa/disable', authenticate,
  [body('password').notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      await authService.disableTotp(req.user.id, req.body.password);
      success(res, { message: '2FA disabled' });
    } catch (err) {
      next(err);
    }
  }
);

// POST /v1/auth/2fa/challenge
router.post('/2fa/challenge',
  authLimiter,
  [body('challengeToken').notEmpty(), body('code').isLength({ min: 6, max: 8 })],
  validate,
  async (req, res, next) => {
    try {
      const result = await authService.verifyTotpChallenge(req.body.challengeToken, req.body.code);
      success(res, result);
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
