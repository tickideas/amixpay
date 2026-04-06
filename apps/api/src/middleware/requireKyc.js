const ApiError = require('../utils/ApiError');

/**
 * Require at least KYC level 1 (phone verified) for financial operations
 */
const requireKyc = (minLevel = 1) => (req, res, next) => {
  const user = req.user;
  if (!user) return next(ApiError.unauthorized('Authentication required'));

  if (user.kyc_level < minLevel) {
    return next(ApiError.forbidden(
      `KYC level ${minLevel} required. Current level: ${user.kyc_level}. Please complete identity verification.`
    ));
  }

  next();
};

module.exports = requireKyc;
