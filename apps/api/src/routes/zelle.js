/**
 * Zelle-style P2P Transfer Routes
 * Base: /v1/zelle
 */

const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const zelleService = require('../services/zelleService');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');

const router = express.Router();
router.use(authenticate);

function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return next(ApiError.badRequest(errors.array()[0].msg));
  next();
}

/**
 * GET /v1/zelle/lookup
 * Look up a recipient by username, email, or phone before sending.
 * Query: ?identifier=...
 */
router.get(
  '/lookup',
  [query('identifier').trim().notEmpty().withMessage('identifier is required')],
  validate,
  async (req, res, next) => {
    try {
      const recipient = await zelleService.lookupRecipient(req.query.identifier);
      if (!recipient) return res.status(404).json({ success: false, error: { code: 'NOT_FOUND', message: 'No AmixPay user found with that username, email, or phone' } });
      success(res, { recipient });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * POST /v1/zelle/send
 * Send an instant in-network Zelle-style transfer.
 */
router.post(
  '/send',
  [
    body('identifier').trim().notEmpty().withMessage('Recipient identifier is required'),
    body('amount').isFloat({ gt: 0 }).withMessage('Amount must be greater than 0'),
    body('currency').trim().isLength({ min: 3, max: 3 }).withMessage('Currency code required'),
    body('note').optional().isString().isLength({ max: 200 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { identifier, amount, currency, note } = req.body;
      const result = await zelleService.sendInNetwork({
        senderId: req.user.id,
        identifier,
        amount: parseFloat(amount),
        currencyCode: currency.toUpperCase(),
        note,
        deviceId: req.headers['x-device-id'],
      });
      success(res, result, 201);
    } catch (err) {
      next(err);
    }
  }
);

/**
 * POST /v1/zelle/send-external
 * Send to an external US Zelle user by email or phone.
 * Only available for US-based accounts.
 */
router.post(
  '/send-external',
  [
    body('amount').isFloat({ gt: 0, max: 2500 }).withMessage('Amount must be between 0 and $2,500'),
    body('recipientEmail').optional().isEmail().withMessage('Valid email required'),
    body('recipientPhone').optional().isMobilePhone().withMessage('Valid phone number required'),
    body('note').optional().isString().isLength({ max: 200 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { amount, recipientEmail, recipientPhone, note } = req.body;
      if (!recipientEmail && !recipientPhone) {
        return next(ApiError.badRequest('Either recipientEmail or recipientPhone is required'));
      }
      const result = await zelleService.sendExternal({
        senderId: req.user.id,
        recipientEmail,
        recipientPhone,
        amount: parseFloat(amount),
        note,
        deviceId: req.headers['x-device-id'],
      });
      success(res, result, 201);
    } catch (err) {
      next(err);
    }
  }
);

/**
 * GET /v1/zelle/history
 * Get Zelle transfer history for the authenticated user.
 * Query: ?limit=20&offset=0&type=in_network|external
 */
router.get('/history', async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = parseInt(req.query.offset) || 0;
    const type = req.query.type; // in_network | external
    const result = await zelleService.getHistory(req.user.id, { limit, offset, type });
    success(res, result);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
