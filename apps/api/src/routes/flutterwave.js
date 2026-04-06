const { Router } = require('express');
const { body, param, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const flutterwaveService = require('../services/flutterwaveService');
const walletService = require('../services/walletService');
const User = require('../db/models/User');
const Transaction = require('../db/models/Transaction');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');

const router = Router();

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  }
  next();
};

// ── POST /v1/flutterwave/verify-payment ──────────────────────────────────────
// Called by Flutter after the Flutterwave SDK returns a successful transaction.
// Verifies the payment server-side (never trust client-side confirmation),
// then credits the user's wallet.
router.post('/verify-payment',
  authenticate,
  [
    body('transactionId').isInt({ gt: 0 }).withMessage('transactionId must be a positive integer'),
    body('txRef').isString().notEmpty().withMessage('txRef is required'),
    body('currency').isLength({ min: 3, max: 3 }).withMessage('Invalid currency'),
    body('amount').isFloat({ gt: 0 }).withMessage('Amount must be positive'),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { transactionId, txRef, currency, amount } = req.body;
      const userId = req.user.id;

      // 1. Verify with Flutterwave API — never trust the client
      const verified = await flutterwaveService.verifyTransaction(transactionId);

      // 2. Double-check: status, txRef, amount, currency all match what was requested
      if (verified.status !== 'successful') {
        throw new ApiError(402, 'Payment was not successful');
      }
      if (verified.txRef !== txRef) {
        throw new ApiError(400, 'Transaction reference mismatch');
      }
      if (verified.currency !== currency.toUpperCase()) {
        throw new ApiError(400, 'Currency mismatch');
      }
      // Allow small rounding differences (±1 unit) but reject large mismatches
      if (Math.abs(verified.amount - parseFloat(amount)) > 1) {
        throw new ApiError(400, 'Amount mismatch');
      }

      // 3. Idempotency — check if this transactionId was already processed
      const existing = await Transaction.findByExternalRef(`flw_${transactionId}`);
      if (existing) {
        return success(res, { alreadyProcessed: true, transaction: existing }, 'Payment already credited');
      }

      // 4. Credit the wallet atomically
      await walletService.creditWallet({
        userId,
        currency: verified.currency,
        amount: verified.amount,
        description: `Flutterwave deposit via ${verified.paymentType}`,
        externalRef: `flw_${transactionId}`,
      });

      success(res, {
        credited: true,
        amount: verified.amount,
        currency: verified.currency,
        transactionId,
      }, 'Wallet credited successfully');
    } catch (err) { next(err); }
  }
);

// ── POST /v1/flutterwave/webhooks ─────────────────────────────────────────────
// Flutterwave sends real-time payment events here.
// Register this URL in the Flutterwave dashboard under Webhooks.
router.post('/webhooks', async (req, res, next) => {
  try {
    const signature = req.headers['verif-hash'];

    // Verify authenticity
    flutterwaveService.verifyWebhookSignature(req.body, signature);

    const event = req.body;
    console.log(`[FLW Webhook] event: ${event.event}, ref: ${event.data?.tx_ref}`);

    if (event.event === 'charge.completed' && event.data?.status === 'successful') {
      const txData = event.data;
      const txRef = txData.tx_ref;

      // txRef format: "amixpay-<userId>-<uuid>" set by Flutter SDK
      // Only auto-credit if txRef follows our format (prevents spoofing)
      const refParts = txRef?.split('-');
      if (refParts?.length >= 2 && refParts[0] === 'amixpay') {
        // Idempotency check
        const existing = await Transaction.findByExternalRef(`flw_${txData.id}`);
        if (!existing) {
          // Find user by email from the transaction
          const user = txData.customer?.email
            ? await User.findByEmail(txData.customer.email)
            : null;

          if (user) {
            await walletService.creditWallet({
              userId: user.id,
              currency: txData.currency,
              amount: parseFloat(txData.charged_amount),
              description: `Flutterwave deposit via ${txData.payment_type}`,
              externalRef: `flw_${txData.id}`,
            });
            console.log(`[FLW Webhook] Credited ${txData.charged_amount} ${txData.currency} to user ${user.id}`);
          }
        }
      }
    }

    // Always respond 200 — Flutterwave retries on non-200
    res.status(200).json({ status: 'ok' });
  } catch (err) {
    // Log but still return 200 to prevent Flutterwave from retrying indefinitely
    console.error('[FLW Webhook] Error:', err.message);
    res.status(200).json({ status: 'ok' });
  }
});

// ── GET /v1/flutterwave/banks/:country ───────────────────────────────────────
router.get('/banks/:country',
  authenticate,
  param('country').isAlpha().isLength({ min: 2, max: 2 }),
  validate,
  async (req, res, next) => {
    try {
      const banks = await flutterwaveService.getBanks(req.params.country.toUpperCase());
      success(res, { banks });
    } catch (err) { next(err); }
  }
);

// ── GET /v1/flutterwave/rates ─────────────────────────────────────────────────
router.get('/rates',
  authenticate,
  async (req, res, next) => {
    try {
      const { from = 'USD', to = 'NGN', amount = 100 } = req.query;
      const rate = await flutterwaveService.getRate({ from, to, amount });
      success(res, { rate });
    } catch (err) { next(err); }
  }
);

module.exports = router;
