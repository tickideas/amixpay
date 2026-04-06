const refreshTokens = new Map();
const blacklist = new Set();

function storeRefreshToken(token, userId, expiresAt) {
  refreshTokens.set(token, { userId, expiresAt });
}

function getRefreshToken(token) {
  const record = refreshTokens.get(token);
  if (!record) return null;
  if (new Date(record.expiresAt) < new Date()) {
    refreshTokens.delete(token);
    return null;
  }
  return record;
}

function deleteRefreshToken(token) {
  refreshTokens.delete(token);
}

function deleteAllForUser(userId) {
  for (const [token, record] of refreshTokens) {
    if (record.userId === userId) {
      refreshTokens.delete(token);
    }
  }
}

function blacklistAccessToken(jti, ttlMs) {
  blacklist.add(jti);
  setTimeout(() => blacklist.delete(jti), ttlMs || 15 * 60 * 1000);
}

function isBlacklisted(jti) {
  return blacklist.has(jti);
}

module.exports = {
  storeRefreshToken,
  getRefreshToken,
  deleteRefreshToken,
  deleteAllForUser,
  blacklistAccessToken,
  isBlacklisted,
};
