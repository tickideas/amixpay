const { Router } = require('express');
const { query, body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const currencyService = require('../services/currencyService');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// GET /v1/currencies
router.get('/', (req, res) => {
  success(res, currencyService.getSupportedCurrencies());
});

// GET /v1/currencies/rates?base=USD
router.get('/rates',
  [query('base').optional().isLength({ min: 3, max: 3 })],
  validate,
  async (req, res, next) => {
    try {
      const rates = await currencyService.getRates(req.query.base || 'USD');
      success(res, { base: req.query.base || 'USD', rates, timestamp: Date.now() });
    } catch (err) { next(err); }
  }
);

// POST /v1/currencies/convert
router.post('/convert',
  [
    body('amount').isFloat({ gt: 0 }),
    body('from').isLength({ min: 3, max: 3 }).toUpperCase(),
    body('to').isLength({ min: 3, max: 3 }).toUpperCase(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const result = await currencyService.convert(
        parseFloat(req.body.amount),
        req.body.from,
        req.body.to
      );
      success(res, {
        from: req.body.from,
        to: req.body.to,
        inputAmount: parseFloat(req.body.amount),
        ...result,
      });
    } catch (err) { next(err); }
  }
);

module.exports = router;
