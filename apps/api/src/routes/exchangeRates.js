const { Router } = require('express');
const { authenticate } = require('../middleware/authenticate');
const currencyService = require('../services/currencyService');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

// GET /v1/exchange-rates — Live rates
router.get('/', async (req, res, next) => {
  try {
    const base = (req.query.base || 'USD').toUpperCase();
    const rates = await currencyService.getRates(base);
    success(res, { base, rates, timestamp: Date.now() });
  } catch (err) { next(err); }
});

module.exports = router;
