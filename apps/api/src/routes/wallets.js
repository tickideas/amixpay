const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const walletService = require('../services/walletService');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// GET /v1/wallets
router.get('/', async (req, res, next) => {
  try {
    const wallet = await walletService.getOrCreateWallet(req.user.id);
    success(res, wallet);
  } catch (err) { next(err); }
});

// POST /v1/wallets/currencies
router.post('/currencies',
  [
    body('currencyCode').isLength({ min: 3, max: 3 }),
    body('colorIndex').optional().isInt({ min: 0, max: 7 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { currencyCode, colorIndex } = req.body;
      const wc = await walletService.addCurrency(
        req.user.id,
        currencyCode.toUpperCase(),
        colorIndex !== undefined ? parseInt(colorIndex) : null,
      );
      res.status(201).json({ success: true, data: wc });
    } catch (err) { next(err); }
  }
);

// DELETE /v1/wallets/currencies/:code
router.delete('/currencies/:code', async (req, res, next) => {
  try {
    const result = await walletService.removeCurrency(req.user.id, req.params.code.toUpperCase());
    success(res, result);
  } catch (err) { next(err); }
});

// GET /v1/wallets/transactions
router.get('/transactions',
  [
    query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
    query('offset').optional().isInt({ min: 0 }).toInt(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const result = await walletService.getTransactions(req.user.id, req.query);
      success(res, result);
    } catch (err) { next(err); }
  }
);

// GET /v1/wallets/transactions/:id
router.get('/transactions/:id', async (req, res, next) => {
  try {
    const txn = await walletService.getTransaction(req.user.id, req.params.id);
    success(res, txn);
  } catch (err) { next(err); }
});

module.exports = router;
