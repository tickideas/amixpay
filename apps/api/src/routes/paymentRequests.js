const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const paymentService = require('../services/paymentService');
const PaymentRequest = require('../db/models/PaymentRequest');
const ApiError = require('../utils/ApiError');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/payment-requests
router.post('/',
  [
    body('payer').notEmpty(),
    body('amount').isFloat({ gt: 0 }),
    body('currencyCode').isLength({ min: 3, max: 3 }).toUpperCase(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { payer, amount, currencyCode, note } = req.body;
      const request = await paymentService.createRequest({
        requesterId: req.user.id,
        payerIdentifier: payer,
        amount: parseFloat(amount),
        currencyCode,
        note,
      });
      res.status(201).json({ success: true, data: request });
    } catch (err) { next(err); }
  }
);

// GET /v1/payment-requests
router.get('/',
  [query('role').optional().isIn(['all', 'requester', 'payer'])],
  validate,
  async (req, res, next) => {
    try {
      const requests = await PaymentRequest.listByUser(req.user.id, {
        ...req.query,
        role: req.query.role || 'all',
      });
      success(res, requests);
    } catch (err) { next(err); }
  }
);

// GET /v1/payment-requests/:id
router.get('/:id', async (req, res, next) => {
  try {
    const request = await PaymentRequest.findById(req.params.id);
    if (!request) return next(ApiError.notFound('Payment request not found'));
    if (request.requester_id !== req.user.id && request.payer_id !== req.user.id) {
      return next(ApiError.forbidden('Access denied'));
    }
    success(res, request);
  } catch (err) { next(err); }
});

// POST /v1/payment-requests/:id/accept
router.post('/:id/accept', async (req, res, next) => {
  try {
    const result = await paymentService.acceptRequest(req.params.id, req.user.id);
    success(res, result);
  } catch (err) { next(err); }
});

// POST /v1/payment-requests/:id/decline
router.post('/:id/decline', async (req, res, next) => {
  try {
    const request = await paymentService.declineRequest(req.params.id, req.user.id);
    success(res, request);
  } catch (err) { next(err); }
});

// POST /v1/payment-requests/:id/cancel
router.post('/:id/cancel', async (req, res, next) => {
  try {
    const request = await PaymentRequest.findById(req.params.id);
    if (!request) return next(ApiError.notFound('Not found'));
    if (request.requester_id !== req.user.id) return next(ApiError.forbidden('Access denied'));
    if (request.status !== 'pending') return next(ApiError.badRequest('Request cannot be cancelled'));
    const updated = await PaymentRequest.update(req.params.id, { status: 'cancelled' });
    success(res, updated);
  } catch (err) { next(err); }
});

module.exports = router;
