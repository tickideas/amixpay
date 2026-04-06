const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');
const db = require('../db/knex');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// GET /v1/savings — list user's savings goals
router.get('/', async (req, res, next) => {
  try {
    const goals = await db('savings_goals')
      .where({ user_id: req.user.id })
      .orderBy('created_at', 'desc');
    success(res, goals);
  } catch (err) { next(err); }
});

// POST /v1/savings — create a new savings goal
router.post('/',
  [
    body('name').trim().notEmpty().isLength({ max: 100 }),
    body('targetAmount').isFloat({ gt: 0 }),
    body('currencyCode').isLength({ min: 3, max: 3 }).toUpperCase(),
    body('targetDate').optional().isISO8601(),
    body('emoji').optional().trim(),
    body('colorIndex').optional().isInt({ min: 0, max: 7 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { name, targetAmount, currencyCode, targetDate, emoji, colorIndex } = req.body;
      const [goal] = await db('savings_goals').insert({
        user_id: req.user.id,
        name,
        target_amount: targetAmount,
        currency_code: currencyCode,
        target_date: targetDate || null,
        emoji: emoji || '🎯',
        color_index: colorIndex ?? 0,
      }).returning('*');
      res.status(201).json({ success: true, data: goal });
    } catch (err) { next(err); }
  }
);

// PATCH /v1/savings/:id — update a savings goal
router.patch('/:id',
  [
    body('name').optional().trim().isLength({ max: 100 }),
    body('targetAmount').optional().isFloat({ gt: 0 }),
    body('targetDate').optional().isISO8601(),
    body('emoji').optional().trim(),
    body('colorIndex').optional().isInt({ min: 0, max: 7 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const goal = await db('savings_goals').where({ id: req.params.id, user_id: req.user.id }).first();
      if (!goal) throw ApiError.notFound('Savings goal not found');

      const updates = {};
      if (req.body.name) updates.name = req.body.name;
      if (req.body.targetAmount) updates.target_amount = req.body.targetAmount;
      if (req.body.targetDate) updates.target_date = req.body.targetDate;
      if (req.body.emoji) updates.emoji = req.body.emoji;
      if (req.body.colorIndex !== undefined) updates.color_index = req.body.colorIndex;

      const [updated] = await db('savings_goals')
        .where({ id: req.params.id })
        .update({ ...updates, updated_at: db.fn.now() })
        .returning('*');
      success(res, updated);
    } catch (err) { next(err); }
  }
);

// POST /v1/savings/:id/deposit — add funds to a savings goal
router.post('/:id/deposit',
  [body('amount').isFloat({ gt: 0 })],
  validate,
  async (req, res, next) => {
    try {
      const goal = await db('savings_goals').where({ id: req.params.id, user_id: req.user.id }).first();
      if (!goal) throw ApiError.notFound('Savings goal not found');
      if (goal.status !== 'active') throw ApiError.badRequest('Goal is not active');

      const newSaved = parseFloat(goal.saved_amount) + parseFloat(req.body.amount);
      const newStatus = newSaved >= parseFloat(goal.target_amount) ? 'completed' : 'active';

      const [updated] = await db('savings_goals')
        .where({ id: req.params.id })
        .update({ saved_amount: newSaved, status: newStatus, updated_at: db.fn.now() })
        .returning('*');
      success(res, updated);
    } catch (err) { next(err); }
  }
);

// POST /v1/savings/:id/withdraw — withdraw funds from a savings goal
router.post('/:id/withdraw',
  [body('amount').isFloat({ gt: 0 })],
  validate,
  async (req, res, next) => {
    try {
      const goal = await db('savings_goals').where({ id: req.params.id, user_id: req.user.id }).first();
      if (!goal) throw ApiError.notFound('Savings goal not found');
      if (parseFloat(req.body.amount) > parseFloat(goal.saved_amount)) {
        throw ApiError.badRequest('Insufficient savings balance');
      }

      const newSaved = parseFloat(goal.saved_amount) - parseFloat(req.body.amount);
      const [updated] = await db('savings_goals')
        .where({ id: req.params.id })
        .update({ saved_amount: newSaved, status: 'active', updated_at: db.fn.now() })
        .returning('*');
      success(res, updated);
    } catch (err) { next(err); }
  }
);

// DELETE /v1/savings/:id — cancel/delete a savings goal
router.delete('/:id', async (req, res, next) => {
  try {
    const goal = await db('savings_goals').where({ id: req.params.id, user_id: req.user.id }).first();
    if (!goal) throw ApiError.notFound('Savings goal not found');
    await db('savings_goals').where({ id: req.params.id }).update({ status: 'cancelled', updated_at: db.fn.now() });
    success(res, { message: 'Savings goal cancelled' });
  } catch (err) { next(err); }
});

module.exports = router;
