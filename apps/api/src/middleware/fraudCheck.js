const fraudService = require('../services/fraudService');

/**
 * Real fraud detection middleware — evaluates velocity, amount, and blacklists via Redis.
 * Sets req.fraudResult for downstream use.
 */
const fraudCheck = async (req, res, next) => {
  if (!req.user) return next();

  try {
    const amount = req.body?.amount || 0;
    const currency = req.body?.currency || req.body?.currencyCode || 'USD';
    const recipientId = req.body?.recipientId || null;

    const result = await fraudService.evaluateTransaction({
      userId: req.user.id,
      amount,
      currencyCode: currency,
      recipientId,
      transactionId: null,
      ipAddress: req.ip,
    });

    req.fraudResult = result;

    if (result.shouldBlock) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'FRAUD_BLOCKED',
          message: 'Transaction blocked due to suspicious activity. Please contact support.',
        },
      });
    }

    next();
  } catch (err) {
    // Don't block on fraud check error
    req.fraudResult = { riskScore: 0, flags: [], shouldBlock: false };
    next();
  }
};

module.exports = fraudCheck;
