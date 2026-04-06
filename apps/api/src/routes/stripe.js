const { Router } = require('express');
const { body, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const stripeService = require('../services/stripeService');
const Wallet = require('../db/models/Wallet');
const User = require('../db/models/User');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');

const router = Router();

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// POST /v1/stripe/payment-intents
router.post('/payment-intents', authenticate,
  [body('amount').isFloat({ gt: 0 }), body('currency').isLength({ min: 3, max: 3 })],
  validate,
  async (req, res, next) => {
    try {
      const user = await User.findById(req.user.id);
      const wallet = await Wallet.findByUserId(req.user.id);
      const customer = await stripeService.createOrGetCustomer(user);

      const intent = await stripeService.createPaymentIntent({
        amount: req.body.amount,
        currency: req.body.currency,
        customerId: customer.id,
        metadata: { userId: req.user.id, ...req.body.metadata },
      });

      success(res, { clientSecret: intent.client_secret, paymentIntentId: intent.id });
    } catch (err) { next(err); }
  }
);

// POST /v1/stripe/webhooks — Stripe sends events here
router.post('/webhooks', express_raw_middleware, async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripeService.verifyWebhookSignature(req.body, sig);
  } catch (err) {
    console.error('[Stripe Webhook] Signature verification failed:', err.message);
    return res.status(400).send('Webhook signature invalid');
  }

  console.log('[Stripe Webhook] Event:', event.type);

  // Handle key events
  switch (event.type) {
    case 'payment_intent.succeeded':
      console.log('[Stripe] PaymentIntent succeeded:', event.data.object.id);
      break;
    case 'payment_intent.payment_failed':
      console.log('[Stripe] PaymentIntent failed:', event.data.object.id);
      break;
    case 'issuing_transaction.created':
      console.log('[Stripe] Issuing transaction:', event.data.object.id);
      break;
    default:
      break;
  }

  res.json({ received: true });
});

// Middleware for raw body (needed for Stripe webhook verification)
function express_raw_middleware(req, res, next) {
  // In app.js this route uses express.raw({ type: 'application/json' })
  // Here we just pass through
  next();
}

module.exports = router;
