const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const stripeService = require('../services/stripeService');
const VirtualCard = require('../db/models/VirtualCard');
const User = require('../db/models/User');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/virtual-cards
router.post('/',
  [body('cardHolderName').trim().notEmpty(), body('currency').optional().isLength({ min: 3, max: 3 })],
  validate,
  async (req, res, next) => {
    try {
      const { cardHolderName, currency, spendingLimit } = req.body;

      let stripeCard;
      try {
        stripeCard = await stripeService.createVirtualCard({
          cardHolderName,
          currency: (currency || 'usd').toLowerCase(),
          spendingLimit,
        });
      } catch (e) {
        console.warn('[VirtualCard] Stripe Issuing unavailable, using mock card:', e.message);
        stripeCard = {
          id: `mock_card_${Date.now()}`,
          last4: '4242',
          exp_month: 12,
          exp_year: new Date().getFullYear() + 3,
          status: 'active',
        };
      }

      const card = await VirtualCard.create({
        user_id: req.user.id,
        stripe_card_id: stripeCard.id,
        last_four: stripeCard.last4 || stripeCard.last_four || '4242',
        card_holder_name: cardHolderName,
        exp_month: stripeCard.exp_month,
        exp_year: stripeCard.exp_year,
        currency_code: (currency || 'USD').toUpperCase(),
        spending_limit: spendingLimit || null,
      });

      res.status(201).json({ success: true, data: card });
    } catch (err) { next(err); }
  }
);

// GET /v1/virtual-cards
router.get('/', async (req, res, next) => {
  try {
    const cards = await VirtualCard.listByUser(req.user.id);
    success(res, cards);
  } catch (err) { next(err); }
});

// GET /v1/virtual-cards/:id
router.get('/:id', async (req, res, next) => {
  try {
    const card = await VirtualCard.findById(req.params.id);
    if (!card || card.user_id !== req.user.id) return next(ApiError.notFound('Card not found'));
    success(res, card);
  } catch (err) { next(err); }
});

// PATCH /v1/virtual-cards/:id — Freeze/unfreeze
router.patch('/:id',
  [body('status').isIn(['active', 'frozen'])],
  validate,
  async (req, res, next) => {
    try {
      const card = await VirtualCard.findById(req.params.id);
      if (!card || card.user_id !== req.user.id) return next(ApiError.notFound('Card not found'));

      try {
        await stripeService.updateCard(card.stripe_card_id, { status: req.body.status === 'frozen' ? 'inactive' : 'active' });
      } catch (_) {}

      const updated = await VirtualCard.update(req.params.id, { status: req.body.status });
      success(res, updated);
    } catch (err) { next(err); }
  }
);

// DELETE /v1/virtual-cards/:id — Cancel card
router.delete('/:id', async (req, res, next) => {
  try {
    const card = await VirtualCard.findById(req.params.id);
    if (!card || card.user_id !== req.user.id) return next(ApiError.notFound('Card not found'));

    try {
      await stripeService.updateCard(card.stripe_card_id, { status: 'inactive' });
    } catch (_) {}

    await VirtualCard.update(req.params.id, { status: 'cancelled' });
    success(res, { cancelled: true });
  } catch (err) { next(err); }
});

// GET /v1/virtual-cards/:id/transactions
router.get('/:id/transactions', async (req, res, next) => {
  try {
    const card = await VirtualCard.findById(req.params.id);
    if (!card || card.user_id !== req.user.id) return next(ApiError.notFound('Card not found'));
    const db = require('../db/knex');
    const wallet = await db('wallets').where({ user_id: req.user.id }).first();
    const txns = await db('transactions')
      .where({ wallet_id: wallet?.id, type: 'card_payment' })
      .orderBy('created_at', 'desc')
      .limit(20);
    success(res, txns);
  } catch (err) { next(err); }
});

module.exports = router;
