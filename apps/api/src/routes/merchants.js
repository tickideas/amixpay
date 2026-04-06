const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate, requireMerchant } = require('../middleware/authenticate');
const merchantService = require('../services/merchantService');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/merchants/register
router.post('/register',
  [body('businessName').trim().notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const merchant = await merchantService.register(req.user.id, req.body);
      res.status(201).json({ success: true, data: merchant });
    } catch (err) { next(err); }
  }
);

// GET /v1/merchants/me
router.get('/me', requireMerchant, async (req, res, next) => {
  try {
    const dashboard = await merchantService.getDashboard(req.user.id);
    success(res, dashboard);
  } catch (err) { next(err); }
});

// PATCH /v1/merchants/me
router.patch('/me', requireMerchant, async (req, res, next) => {
  try {
    const merchant = await merchantService.update(req.user.id, req.body);
    success(res, merchant);
  } catch (err) { next(err); }
});

// POST /v1/merchants/payments
router.post('/payments', requireMerchant,
  [body('amount').isFloat({ gt: 0 }), body('currencyCode').isLength({ min: 3, max: 3 })],
  validate,
  async (req, res, next) => {
    try {
      const db = require('../db/knex');
      const merchant = await db('merchants').where({ user_id: req.user.id }).first();
      const payment = await merchantService.createPayment(merchant.id, req.body);
      res.status(201).json({ success: true, data: payment });
    } catch (err) { next(err); }
  }
);

// GET /v1/merchants/payments
router.get('/payments', requireMerchant, async (req, res, next) => {
  try {
    const payments = await merchantService.listPayments(req.user.id, req.query);
    success(res, payments);
  } catch (err) { next(err); }
});

// POST /v1/merchants/checkout-link
router.post('/checkout-link', requireMerchant,
  [body('title').trim().notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const link = await merchantService.createCheckoutLink(req.user.id, req.body);
      res.status(201).json({ success: true, data: link });
    } catch (err) { next(err); }
  }
);

// GET /v1/merchants/checkout-link/:slug — Public endpoint
router.get('/checkout-link/:slug', async (req, res, next) => {
  try {
    const link = await merchantService.getCheckoutLink(req.params.slug);
    success(res, link);
  } catch (err) { next(err); }
});

// GET /v1/merchants/stripe/connect
router.get('/stripe/connect', requireMerchant, async (req, res, next) => {
  try {
    const link = await merchantService.getStripeConnectLink(req.user.id);
    success(res, link);
  } catch (err) { next(err); }
});

module.exports = router;
