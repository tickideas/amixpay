const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const { validateAmount } = require('../middleware/validateAmount');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');
const db = require('../db/knex');
const User = require('../db/models/User');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// GET /v1/scheduled — list user's scheduled transfers
router.get('/', async (req, res, next) => {
  try {
    const transfers = await db('scheduled_transfers')
      .where({ user_id: req.user.id })
      .orderBy('next_run_date', 'asc');
    success(res, transfers);
  } catch (err) { next(err); }
});

// POST /v1/scheduled — create a new scheduled transfer
router.post('/',
  [
    body('recipient').notEmpty(),
    body('amount').isFloat({ gt: 0 }),
    body('currencyCode').isLength({ min: 3, max: 3 }).toUpperCase(),
    body('frequency').isIn(['once', 'daily', 'weekly', 'biweekly', 'monthly']),
    body('nextRunDate').isISO8601(),
    body('endDate').optional().isISO8601(),
    body('description').optional().trim(),
  ],
  validate,
  validateAmount('amount'),
  async (req, res, next) => {
    try {
      const { recipient, amount, currencyCode, frequency, nextRunDate, endDate, description } = req.body;

      // Verify recipient exists
      const recipientUser = await User.findByIdentifier(recipient);
      if (!recipientUser) throw ApiError.notFound('Recipient not found');
      if (recipientUser.id === req.user.id) throw ApiError.badRequest('Cannot schedule transfer to yourself');

      const [transfer] = await db('scheduled_transfers').insert({
        user_id: req.user.id,
        recipient_identifier: recipient,
        recipient_name: `${recipientUser.first_name} ${recipientUser.last_name}`,
        amount,
        currency_code: currencyCode,
        description: description || null,
        frequency,
        next_run_date: nextRunDate,
        end_date: endDate || null,
      }).returning('*');
      res.status(201).json({ success: true, data: transfer });
    } catch (err) { next(err); }
  }
);

// GET /v1/scheduled/:id
router.get('/:id', async (req, res, next) => {
  try {
    const transfer = await db('scheduled_transfers')
      .where({ id: req.params.id, user_id: req.user.id }).first();
    if (!transfer) throw ApiError.notFound('Scheduled transfer not found');
    success(res, transfer);
  } catch (err) { next(err); }
});

// PATCH /v1/scheduled/:id — update (pause, resume, change amount, etc.)
router.patch('/:id',
  [
    body('amount').optional().isFloat({ gt: 0 }),
    body('frequency').optional().isIn(['once', 'daily', 'weekly', 'biweekly', 'monthly']),
    body('nextRunDate').optional().isISO8601(),
    body('status').optional().isIn(['active', 'paused', 'cancelled']),
    body('description').optional().trim(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const transfer = await db('scheduled_transfers')
        .where({ id: req.params.id, user_id: req.user.id }).first();
      if (!transfer) throw ApiError.notFound('Scheduled transfer not found');

      const updates = {};
      if (req.body.amount) updates.amount = req.body.amount;
      if (req.body.frequency) updates.frequency = req.body.frequency;
      if (req.body.nextRunDate) updates.next_run_date = req.body.nextRunDate;
      if (req.body.status) updates.status = req.body.status;
      if (req.body.description !== undefined) updates.description = req.body.description;

      const [updated] = await db('scheduled_transfers')
        .where({ id: req.params.id })
        .update({ ...updates, updated_at: db.fn.now() })
        .returning('*');
      success(res, updated);
    } catch (err) { next(err); }
  }
);

// DELETE /v1/scheduled/:id — cancel a scheduled transfer
router.delete('/:id', async (req, res, next) => {
  try {
    const transfer = await db('scheduled_transfers')
      .where({ id: req.params.id, user_id: req.user.id }).first();
    if (!transfer) throw ApiError.notFound('Scheduled transfer not found');
    await db('scheduled_transfers')
      .where({ id: req.params.id })
      .update({ status: 'cancelled', updated_at: db.fn.now() });
    success(res, { message: 'Scheduled transfer cancelled' });
  } catch (err) { next(err); }
});

module.exports = router;
