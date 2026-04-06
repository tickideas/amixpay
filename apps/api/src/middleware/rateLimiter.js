const rateLimit = require('express-rate-limit');

const createLimiter = (options) => {
  return rateLimit({
    windowMs: options.windowMs,
    max: options.max,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
      success: false,
      error: { code: 'RATE_LIMITED', message: options.message || 'Too many requests, please try again later.' },
    },
    skip: (req) => process.env.NODE_ENV === 'test',
    validate: false,
  });
};

// Auth endpoints: strict (5 per minute)
const authLimiter = createLimiter({
  windowMs: 60 * 1000,
  max: 10,
  message: 'Too many auth attempts. Please wait before trying again.',
});

// Payment endpoints: moderate (30 per minute)
const paymentLimiter = createLimiter({
  windowMs: 60 * 1000,
  max: 30,
  message: 'Too many payment requests.',
});

// General API: relaxed (120 per minute)
const generalLimiter = createLimiter({
  windowMs: 60 * 1000,
  max: 120,
});

module.exports = { authLimiter, paymentLimiter, generalLimiter };
