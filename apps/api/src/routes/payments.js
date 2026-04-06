const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const fraudCheck = require('../middleware/fraudCheck');
const paymentService = require('../services/paymentService');
const Payment = require('../db/models/Payment');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/payments/send
router.post('/send',
  fraudCheck,
  [
    body('recipient').notEmpty().withMessage('Recipient (username/email/phone) is required'),
    body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
    body('currencyCode').isLength({ min: 3, max: 3 }).toUpperCase(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { recipient, amount, currencyCode, note } = req.body;
      const result = await paymentService.send({
        senderId: req.user.id,
        recipientIdentifier: recipient,
        amount: parseFloat(amount),
        currencyCode,
        note,
      });
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  }
);

// GET /v1/payments/:id
router.get('/:id', async (req, res, next) => {
  try {
    const payment = await Payment.findById(req.params.id);
    if (!payment) return next(ApiError.notFound('Payment not found'));
    if (payment.sender_id !== req.user.id && payment.recipient_id !== req.user.id) {
      return next(ApiError.forbidden('Access denied'));
    }
    success(res, payment);
  } catch (err) { next(err); }
});

// POST /v1/payments/cancel/:id
router.post('/cancel/:id', async (req, res, next) => {
  try {
    const payment = await Payment.findById(req.params.id);
    if (!payment) return next(ApiError.notFound('Payment not found'));
    if (payment.sender_id !== req.user.id) return next(ApiError.forbidden('Access denied'));
    if (payment.status !== 'pending') return next(ApiError.badRequest('Only pending payments can be cancelled'));
    const updated = await Payment.update(req.params.id, { status: 'cancelled' });
    success(res, updated);
  } catch (err) { next(err); }
});

module.exports = router;
