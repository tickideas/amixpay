const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const crypto = require('crypto');
const { authenticate } = require('../middleware/authenticate');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');
const db = require('../db/knex');

const router = Router();
router.use(authenticate);

const REWARD_AMOUNT = 5.00; // Reward per qualified referral
const REWARD_CURRENCY = 'USD';

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// Generate a unique referral code from user ID
function generateCode(userId) {
  const hash = crypto.createHash('sha256').update(userId).digest('hex');
  return `AMIX-${hash.substring(0, 6).toUpperCase()}`;
}

// GET /v1/referrals/my-code — get or create the user's referral code
router.get('/my-code', async (req, res, next) => {
  try {
    let ref = await db('referral_codes').where({ user_id: req.user.id }).first();
    if (!ref) {
      const code = generateCode(req.user.id);
      [ref] = await db('referral_codes').insert({
        user_id: req.user.id,
        code,
        reward_currency: REWARD_CURRENCY,
      }).returning('*');
    }
    success(res, {
      code: ref.code,
      link: `https://amixpay.app/join/${ref.code}`,
      totalReferrals: ref.total_referrals,
      totalEarned: parseFloat(ref.total_earned),
      rewardCurrency: ref.reward_currency,
      rewardPerReferral: REWARD_AMOUNT,
    });
  } catch (err) { next(err); }
});

// GET /v1/referrals — list referrals made by this user
router.get('/', async (req, res, next) => {
  try {
    const referrals = await db('referrals')
      .where({ referrer_id: req.user.id })
      .join('users', 'referrals.referred_id', 'users.id')
      .select(
        'referrals.id',
        'referrals.status',
        'referrals.reward_amount',
        'referrals.reward_currency',
        'referrals.created_at',
        'referrals.qualified_at',
        'referrals.rewarded_at',
        'users.first_name',
        'users.last_name',
        'users.avatar_url',
      )
      .orderBy('referrals.created_at', 'desc');

    success(res, referrals);
  } catch (err) { next(err); }
});

// POST /v1/referrals/apply — apply a referral code (called during registration)
// Note: this is typically called from the register flow, not directly
router.post('/apply',
  [body('code').trim().notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const { code } = req.body;

      // Find the referral code
      const refCode = await db('referral_codes').where({ code: code.toUpperCase() }).first();
      if (!refCode) throw ApiError.notFound('Invalid referral code');
      if (refCode.user_id === req.user.id) throw ApiError.badRequest('Cannot use your own referral code');

      // Check if user was already referred
      const existing = await db('referrals').where({ referred_id: req.user.id }).first();
      if (existing) throw ApiError.conflict('You have already used a referral code');

      // Create the referral record
      const [referral] = await db('referrals').insert({
        referrer_id: refCode.user_id,
        referred_id: req.user.id,
        code_used: code.toUpperCase(),
        reward_amount: REWARD_AMOUNT,
        reward_currency: REWARD_CURRENCY,
      }).returning('*');

      // Update referral code stats
      await db('referral_codes')
        .where({ id: refCode.id })
        .increment('total_referrals', 1);

      success(res, { message: 'Referral code applied successfully', referral });
    } catch (err) { next(err); }
  }
);

// GET /v1/referrals/stats — referral summary for current user
router.get('/stats', async (req, res, next) => {
  try {
    const refCode = await db('referral_codes').where({ user_id: req.user.id }).first();
    const pending = await db('referrals').where({ referrer_id: req.user.id, status: 'pending' }).count('id as count').first();
    const qualified = await db('referrals').where({ referrer_id: req.user.id, status: 'qualified' }).count('id as count').first();
    const rewarded = await db('referrals').where({ referrer_id: req.user.id, status: 'rewarded' }).count('id as count').first();

    success(res, {
      code: refCode?.code || null,
      totalReferrals: refCode?.total_referrals || 0,
      totalEarned: parseFloat(refCode?.total_earned || 0),
      pending: parseInt(pending?.count || 0),
      qualified: parseInt(qualified?.count || 0),
      rewarded: parseInt(rewarded?.count || 0),
      rewardPerReferral: REWARD_AMOUNT,
      rewardCurrency: REWARD_CURRENCY,
    });
  } catch (err) { next(err); }
});

module.exports = router;
