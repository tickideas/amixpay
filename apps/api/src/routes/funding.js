const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const stripeService = require('../services/stripeService');
const plaidService = require('../services/plaidService');
const walletService = require('../services/walletService');
const Wallet = require('../db/models/Wallet');
const User = require('../db/models/User');
const db = require('../db/knex');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/funding/bank-accounts — Plaid link token
router.post('/bank-accounts/link-token', async (req, res, next) => {
  try {
    const result = await plaidService.createLinkToken(req.user.id);
    success(res, result);
  } catch (err) { next(err); }
});

// POST /v1/funding/bank-accounts — Exchange Plaid public token
router.post('/bank-accounts',
  [body('publicToken').notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const { access_token, item_id } = await plaidService.exchangePublicToken(req.body.publicToken);
      await Wallet.update((await Wallet.findByUserId(req.user.id)).id, { plaid_access_token: access_token });
      const accounts = await plaidService.getAccounts(access_token);
      success(res, { itemId: item_id, accounts });
    } catch (err) { next(err); }
  }
);

// GET /v1/funding/bank-accounts
router.get('/bank-accounts', async (req, res, next) => {
  try {
    const wallet = await Wallet.findByUserId(req.user.id);
    if (!wallet?.plaid_access_token) return success(res, []);
    const accounts = await plaidService.getAccounts(wallet.plaid_access_token);
    success(res, accounts);
  } catch (err) { next(err); }
});

// POST /v1/funding/deposit — Create Stripe PaymentIntent for card deposit
router.post('/deposit',
  [body('amount').isFloat({ gt: 0 }), body('currency').isLength({ min: 3, max: 3 })],
  validate,
  async (req, res, next) => {
    try {
      const user = await User.findById(req.user.id);
      let wallet = await Wallet.findByUserId(req.user.id);

      // Get or create Stripe customer
      let customerId = wallet?.stripe_customer_id;
      if (!customerId) {
        const customer = await stripeService.createOrGetCustomer(user);
        customerId = customer.id;
        await Wallet.update(wallet.id, { stripe_customer_id: customerId });
      }

      const intent = await stripeService.createPaymentIntent({
        amount: req.body.amount,
        currency: req.body.currency,
        customerId,
        metadata: { userId: req.user.id, purpose: 'wallet_funding' },
      });

      success(res, {
        clientSecret: intent.client_secret,
        paymentIntentId: intent.id,
        amount: req.body.amount,
        currency: req.body.currency,
      });
    } catch (err) { next(err); }
  }
);

// POST /v1/funding/deposit/confirm — Confirm deposit and credit wallet
router.post('/deposit/confirm',
  [body('paymentIntentId').notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const intent = await stripeService.confirmPaymentIntent(req.body.paymentIntentId);
      if (intent.status !== 'succeeded') {
        return next(ApiError.badRequest(`Payment not succeeded. Status: ${intent.status}`));
      }

      const amount = intent.amount / 100;
      const currency = intent.currency.toUpperCase();
      const wallet = await Wallet.findByUserId(req.user.id);

      await db.transaction(async (trx) => {
        const txn = await trx('transactions').insert({
          wallet_id: wallet.id,
          type: 'fund',
          status: 'completed',
          amount,
          currency_code: currency,
          reference_id: `FUND-${intent.id}`,
          description: 'Card deposit',
          metadata: JSON.stringify({ paymentIntentId: intent.id }),
        }).returning('*').then((r) => r[0]);

        await walletService.creditWallet(trx, { walletId: wallet.id, currencyCode: currency, amount, transactionId: txn.id });
      });

      success(res, { credited: true, amount, currency });
    } catch (err) { next(err); }
  }
);

// GET /v1/funding/transactions
router.get('/transactions', async (req, res, next) => {
  try {
    const wallet = await Wallet.findByUserId(req.user.id);
    if (!wallet) return success(res, []);
    const txns = await db('transactions')
      .where({ wallet_id: wallet.id })
      .whereIn('type', ['fund', 'withdraw'])
      .orderBy('created_at', 'desc')
      .limit(50);
    success(res, txns);
  } catch (err) { next(err); }
});

module.exports = router;
