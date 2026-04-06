const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const fraudCheck = require('../middleware/fraudCheck');
const { validateAmount } = require('../middleware/validateAmount');
const transferService = require('../services/transferService');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/transfers/international/quote
router.post('/international/quote',
  [
    body('sourceCurrency').isLength({ min: 3, max: 3 }).toUpperCase(),
    body('targetCurrency').isLength({ min: 3, max: 3 }).toUpperCase(),
    body('sourceAmount').isFloat({ gt: 0 }),
  ],
  validate,
  validateAmount('sourceAmount'),
  async (req, res, next) => {
    try {
      const quote = await transferService.createQuote({
        userId: req.user.id,
        sourceCurrency: req.body.sourceCurrency,
        targetCurrency: req.body.targetCurrency,
        sourceAmount: parseFloat(req.body.sourceAmount),
      });
      success(res, quote);
    } catch (err) { next(err); }
  }
);

// POST /v1/transfers/international
router.post('/international',
  fraudCheck,
  [
    body('sourceAmount').isFloat({ gt: 0 }),
    body('sourceCurrency').isLength({ min: 3, max: 3 }).toUpperCase(),
    body('targetCurrency').isLength({ min: 3, max: 3 }).toUpperCase(),
    body('recipientDetails.name').notEmpty(),
  ],
  validate,
  validateAmount('sourceAmount'),
  async (req, res, next) => {
    try {
      const { quoteId, sourceAmount, sourceCurrency, targetCurrency, targetAmount, rate, fee, recipientDetails } = req.body;
      const result = await transferService.createTransfer({
        userId: req.user.id,
        quoteId: quoteId || `LOCAL-${Date.now()}`,
        sourceAmount: parseFloat(sourceAmount),
        sourceCurrency,
        targetCurrency,
        targetAmount: parseFloat(targetAmount || 0),
        rate: parseFloat(rate || 1),
        fee: parseFloat(fee || 0),
        recipientDetails,
      });
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  }
);

// GET /v1/transfers/international
router.get('/international',
  [query('limit').optional().isInt({ min: 1, max: 100 }).toInt(), query('offset').optional().isInt({ min: 0 }).toInt()],
  validate,
  async (req, res, next) => {
    try {
      const transfers = await transferService.listTransfers(req.user.id, req.query);
      success(res, transfers);
    } catch (err) { next(err); }
  }
);

// GET /v1/transfers/international/:id
router.get('/international/:id', async (req, res, next) => {
  try {
    const transfer = await transferService.getTransfer(req.user.id, req.params.id);
    success(res, transfer);
  } catch (err) { next(err); }
});

// GET /v1/transfers/international/countries
router.get('/international/countries', (req, res) => {
  success(res, transferService.getSupportedCountries());
});

module.exports = router;
