const ApiError = require('../utils/ApiError');

// ── Amount validation middleware ────────────────────────────────────────────
// Ensures financial amounts are safe numbers within sane limits.
// Applied on top of express-validator's isFloat({ gt: 0 }).

const KYC_LIMITS = {
  0: { perTransaction: 500, daily: 1000 },       // Unverified
  1: { perTransaction: 5000, daily: 10000 },      // Phone verified
  2: { perTransaction: 25000, daily: 50000 },     // ID verified
  3: { perTransaction: 100000, daily: 250000 },   // Full KYC
};

const ABSOLUTE_MAX = 1_000_000; // Hard cap regardless of KYC

function validateAmount(amountField = 'amount') {
  return (req, res, next) => {
    const raw = req.body[amountField];
    const amount = parseFloat(raw);

    // Guard against NaN, Infinity, negative, zero
    if (!Number.isFinite(amount) || amount <= 0) {
      return next(ApiError.badRequest(`${amountField} must be a positive number`));
    }

    // Guard against absurdly small amounts (dust attacks)
    if (amount < 0.01) {
      return next(ApiError.badRequest(`${amountField} must be at least 0.01`));
    }

    // Hard cap
    if (amount > ABSOLUTE_MAX) {
      return next(ApiError.badRequest(`${amountField} exceeds maximum allowed (${ABSOLUTE_MAX.toLocaleString()})`));
    }

    // KYC-based limits (if user is authenticated)
    if (req.user) {
      const kycLevel = req.user.kyc_level || 0;
      const limits = KYC_LIMITS[kycLevel] || KYC_LIMITS[0];
      if (amount > limits.perTransaction) {
        return next(ApiError.badRequest(
          `Amount exceeds your per-transaction limit of ${limits.perTransaction.toLocaleString()}. ` +
          `Complete KYC verification to increase your limits.`
        ));
      }
    }

    // Normalize to 2 decimal places for fiat (8 for crypto in future)
    req.body[amountField] = parseFloat(amount.toFixed(2));
    next();
  };
}

module.exports = { validateAmount, KYC_LIMITS };
