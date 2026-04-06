const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const qrService = require('../services/qrService');
const paymentService = require('../services/paymentService');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/qr/generate
router.post('/generate',
  [body('amount').optional().isFloat({ gt: 0 }), body('currency').optional().isLength({ min: 3, max: 3 })],
  validate,
  async (req, res, next) => {
    try {
      const { amount, currency, description } = req.body;
      const result = await qrService.generate({
        userId: req.user.id,
        username: req.user.username,
        amount,
        currency,
        description,
      });
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  }
);

// POST /v1/qr/parse
router.post('/parse',
  [body('payload').notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const result = await qrService.parse(req.body.payload);
      success(res, result);
    } catch (err) { next(err); }
  }
);

// POST /v1/qr/pay
router.post('/pay',
  [body('payload').notEmpty(), body('amount').isFloat({ gt: 0 })],
  validate,
  async (req, res, next) => {
    try {
      const parsed = await qrService.parse(req.body.payload);
      if (!parsed.valid) return res.status(400).json({ success: false, error: { message: 'Invalid QR code' } });

      const amount = req.body.amount || parsed.data.amount;
      const currency = req.body.currency || parsed.data.currency || 'USD';

      const result = await paymentService.send({
        senderId: req.user.id,
        recipientIdentifier: parsed.data.userId || parsed.data.to,
        amount: parseFloat(amount),
        currencyCode: currency,
        note: `QR Payment: ${parsed.data.description || ''}`,
      });

      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  }
);

// GET /v1/qr/my-codes
router.get('/my-codes', async (req, res, next) => {
  try {
    const codes = await qrService.listMyCodes(req.user.id);
    success(res, codes);
  } catch (err) { next(err); }
});

// DELETE /v1/qr/:id
router.delete('/:id', async (req, res, next) => {
  try {
    await qrService.deactivate(req.params.id, req.user.id);
    success(res, { deactivated: true });
  } catch (err) { next(err); }
});

module.exports = router;
