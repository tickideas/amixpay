const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const paymentService = require('../services/paymentService');
const PaymentRequest = require('../db/models/PaymentRequest');
const User = require('../db/models/User');
const ApiError = require('../utils/ApiError');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/splits
router.post('/',
  [
    body('title').trim().notEmpty(),
    body('items').isArray({ min: 1 }),
    body('participants').isArray({ min: 1 }),
    body('currencyCode').isLength({ min: 3, max: 3 }).toUpperCase(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { title, items, participants, currencyCode, taxAmount, discountAmount } = req.body;
      // Resolve participant identifiers to user IDs
      const participantUsers = await Promise.all(
        participants.map((p) => User.findByIdentifier(p))
      );
      const participantIds = participantUsers.filter(Boolean).map((u) => u.id);

      const result = await paymentService.createSplit({
        creatorId: req.user.id,
        participantIds,
        title,
        items,
        currencyCode,
        taxAmount: parseFloat(taxAmount || 0),
        discountAmount: parseFloat(discountAmount || 0),
      });
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  }
);

// GET /v1/splits
router.get('/', async (req, res, next) => {
  try {
    const splits = await PaymentRequest.listSplits(req.user.id, req.query);
    success(res, splits);
  } catch (err) { next(err); }
});

// GET /v1/splits/:id
router.get('/:id', async (req, res, next) => {
  try {
    const split = await PaymentRequest.findSplitById(req.params.id);
    if (!split) return next(ApiError.notFound('Split not found'));
    const shares = await PaymentRequest.getShares(split.id);
    success(res, { split, shares });
  } catch (err) { next(err); }
});

// POST /v1/splits/:id/pay
router.post('/:id/pay', async (req, res, next) => {
  try {
    const split = await PaymentRequest.findSplitById(req.params.id);
    if (!split) return next(ApiError.notFound('Split not found'));

    const shares = await PaymentRequest.getShares(split.id);
    const myShare = shares.find((s) => s.user_id === req.user.id);
    if (!myShare) return next(ApiError.forbidden('You are not a participant in this split'));
    if (myShare.status === 'paid') return next(ApiError.badRequest('You have already paid'));

    const creator = await User.findById(split.creator_id);
    const result = await paymentService.send({
      senderId: req.user.id,
      recipientIdentifier: creator.email,
      amount: parseFloat(myShare.amount),
      currencyCode: split.currency_code,
      note: `Split payment: ${split.title}`,
    });

    await PaymentRequest.updateShare(myShare.id, { status: 'paid', payment_id: result.payment.id });
    success(res, { share: myShare, payment: result.payment });
  } catch (err) { next(err); }
});

// POST /v1/splits/:id/remind — Send reminders (notif only)
router.post('/:id/remind', async (req, res, next) => {
  try {
    const split = await PaymentRequest.findSplitById(req.params.id);
    if (!split || split.creator_id !== req.user.id) return next(ApiError.forbidden('Access denied'));
    const notificationService = require('../services/notificationService');
    const shares = await PaymentRequest.getShares(split.id);
    const pendingShares = shares.filter((s) => s.status === 'pending');
    await Promise.all(pendingShares.map((s) =>
      notificationService.create({
        userId: s.user_id,
        type: 'payment_request',
        title: 'Split Payment Reminder',
        body: `You owe ${split.currency_code} ${s.amount} for "${split.title}"`,
        data: { splitId: split.id },
      })
    ));
    success(res, { reminded: pendingShares.length });
  } catch (err) { next(err); }
});

// DELETE /v1/splits/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const split = await PaymentRequest.findSplitById(req.params.id);
    if (!split || split.creator_id !== req.user.id) return next(ApiError.forbidden('Access denied'));
    await PaymentRequest.updateSplit(split.id, { status: 'cancelled' });
    success(res, { cancelled: true });
  } catch (err) { next(err); }
});

module.exports = router;
