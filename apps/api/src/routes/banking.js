/**
 * Banking Rail Routes
 * Base: /v1/banking
 */

const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const bankingRailService = require('../services/bankingRailService');
const countryWalletService = require('../services/countryWalletService');
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
 * GET /v1/banking/rails
 * List available banking rails, optionally filtered by country/currency.
 * Query: ?country=US&currency=USD
 */
router.get('/rails', async (req, res, next) => {
  try {
    const { country, currency } = req.query;
    const rails = await bankingRailService.getAvailableRails(country, currency);
    success(res, { rails });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /v1/banking/rails/definitions
 * Return the full in-memory rail definitions (for the Flutter app to show fees/times).
 */
router.get('/rails/definitions', (req, res) => {
  const defs = Object.entries(bankingRailService.RAIL_DEFINITIONS).map(([code, def]) => ({
    code,
    name: def.name,
    settlementHours: def.settlementHours,
    isInstant: def.settlementHours === 0,
    maxAmount: def.maxAmount,
    currencies: def.currencies,
    regions: def.regions,
    feeType: def.feeType,
    flatFee: def.flatFee,
    percentFee: def.percentFee,
  }));
  success(res, { definitions: defs });
});

/**
 * POST /v1/banking/quote
 * Get a transfer quote: rail selection, fees, exchange rate, receive amount.
 */
router.post(
  '/quote',
  [
    body('fromCurrency').trim().isLength({ min: 3, max: 3 }).withMessage('fromCurrency required'),
    body('toCurrency').trim().isLength({ min: 3, max: 3 }).withMessage('toCurrency required'),
    body('fromCountry').trim().isLength({ min: 2, max: 2 }).withMessage('fromCountry (ISO alpha-2) required'),
    body('toCountry').trim().isLength({ min: 2, max: 2 }).withMessage('toCountry (ISO alpha-2) required'),
    body('amount').isFloat({ gt: 0 }).withMessage('amount must be > 0'),
    body('preferInstant').optional().isBoolean(),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { fromCurrency, toCurrency, fromCountry, toCountry, amount, preferInstant } = req.body;
      const quote = await bankingRailService.getTransferQuote({
        fromCurrency: fromCurrency.toUpperCase(),
        toCurrency: toCurrency.toUpperCase(),
        fromCountry: fromCountry.toUpperCase(),
        toCountry: toCountry.toUpperCase(),
        amount: parseFloat(amount),
        preferInstant: preferInstant !== false,
      });
      success(res, { quote });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * GET /v1/banking/country-config
 * Get the banking config for a given country (currency, primary rail, limits).
 * Query: ?country=NG
 */
router.get('/country-config', async (req, res, next) => {
  try {
    const { country } = req.query;
    if (!country) return next(ApiError.badRequest('country query parameter required'));
    const config = countryWalletService.getCountryConfig(country.toUpperCase());
    success(res, { countryCode: country.toUpperCase(), ...config });
  } catch (err) {
    next(err);
  }
});

/**
 * GET /v1/banking/country-configs
 * Return all supported country configurations.
 */
router.get('/country-configs', (req, res) => {
  success(res, { countries: countryWalletService.getAllCountryConfigs() });
});

/**
 * GET /v1/banking/transactions
 * Get banking rail transaction history for the authenticated user.
 * Query: ?limit=20&offset=0
 */
router.get('/transactions', async (req, res, next) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 100);
    const offset = parseInt(req.query.offset) || 0;
    const result = await bankingRailService.getTransactionHistory(req.user.id, { limit, offset });
    success(res, result);
  } catch (err) {
    next(err);
  }
});

/**
 * POST /v1/banking/transfer
 * Initiate a bank transfer using a selected rail.
 * This delegates to the appropriate banking service based on rail.
 */
router.post(
  '/transfer',
  [
    body('railCode').trim().notEmpty().withMessage('railCode required'),
    body('amount').isFloat({ gt: 0 }).withMessage('amount must be > 0'),
    body('currency').trim().isLength({ min: 3, max: 3 }).withMessage('currency required'),
    body('recipientAccount').notEmpty().withMessage('recipientAccount required'),
    body('recipientName').notEmpty().withMessage('recipientName required'),
    body('recipientBank').optional().isString(),
    body('note').optional().isString().isLength({ max: 200 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { railCode, amount, currency, recipientAccount, recipientName, recipientBank, note } = req.body;
      const wallet = require('../db/models/Wallet');
      const Wallet = wallet;
      const userWallet = await Wallet.findByUserId(req.user.id);
      if (!userWallet) return next(ApiError.notFound('Wallet not found'));

      // Record the banking transaction
      const tx = await bankingRailService.recordTransaction({
        userId: req.user.id,
        walletId: userWallet.id,
        railCode: railCode.toUpperCase(),
        type: 'outbound',
        amount: parseFloat(amount),
        currency: currency.toUpperCase(),
        status: 'pending',
        metadata: {
          recipientAccount,
          recipientName,
          recipientBank,
          note,
        },
      });

      success(res, {
        transactionId: tx.id,
        reference: tx.reference,
        status: 'pending',
        rail: railCode.toUpperCase(),
        message: 'Banking transfer initiated. Processing times vary by rail.',
      }, 201);
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
