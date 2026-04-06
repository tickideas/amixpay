/**
 * countryWalletService.js
 * Auto-assigns default wallet currency + banking rail based on user country.
 * Called during registration to bootstrap a user's wallet.
 */

const db = require('../db/knex');
const Wallet = require('../db/models/Wallet');
const ApiError = require('../utils/ApiError');

// Country → { currency, primaryRail, secondaryRail, dailyLimit, monthlyLimit }
const COUNTRY_CONFIG = {
  // North America
  US: { currency: 'USD', primaryRail: 'ACH_INSTANT', secondaryRail: 'ACH',       dailyLimit: 10000, monthlyLimit: 50000 },
  CA: { currency: 'CAD', primaryRail: 'ETRANSFER',   secondaryRail: 'ACH',       dailyLimit: 10000, monthlyLimit: 50000 },
  MX: { currency: 'MXN', primaryRail: 'SWIFT',        secondaryRail: null,        dailyLimit: 5000,  monthlyLimit: 25000 },

  // Europe
  GB: { currency: 'GBP', primaryRail: 'FPS',          secondaryRail: 'BACS',      dailyLimit: 10000, monthlyLimit: 50000 },
  DE: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  FR: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  IT: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  ES: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  NL: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  BE: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  PT: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  AT: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  IE: { currency: 'EUR', primaryRail: 'SEPA_INSTANT',  secondaryRail: 'SEPA',      dailyLimit: 10000, monthlyLimit: 50000 },
  CH: { currency: 'CHF', primaryRail: 'SEPA',          secondaryRail: 'SWIFT',     dailyLimit: 10000, monthlyLimit: 50000 },
  SE: { currency: 'SEK', primaryRail: 'SEPA',          secondaryRail: 'SWIFT',     dailyLimit: 10000, monthlyLimit: 50000 },
  NO: { currency: 'NOK', primaryRail: 'SEPA',          secondaryRail: 'SWIFT',     dailyLimit: 10000, monthlyLimit: 50000 },
  DK: { currency: 'DKK', primaryRail: 'SEPA',          secondaryRail: 'SWIFT',     dailyLimit: 10000, monthlyLimit: 50000 },
  PL: { currency: 'PLN', primaryRail: 'SEPA',          secondaryRail: 'SWIFT',     dailyLimit: 10000, monthlyLimit: 50000 },

  // Africa
  NG: { currency: 'NGN', primaryRail: 'NGIP',          secondaryRail: 'SWIFT',     dailyLimit: 5000000, monthlyLimit: 20000000 },
  GH: { currency: 'GHS', primaryRail: 'SWIFT',          secondaryRail: null,        dailyLimit: 10000, monthlyLimit: 50000 },
  KE: { currency: 'KES', primaryRail: 'SWIFT',          secondaryRail: null,        dailyLimit: 500000, monthlyLimit: 2000000 },
  ZA: { currency: 'ZAR', primaryRail: 'SWIFT',          secondaryRail: null,        dailyLimit: 100000, monthlyLimit: 500000 },
  UG: { currency: 'UGX', primaryRail: 'SWIFT',          secondaryRail: null,        dailyLimit: 5000000, monthlyLimit: 20000000 },
  TZ: { currency: 'TZS', primaryRail: 'SWIFT',          secondaryRail: null,        dailyLimit: 5000000, monthlyLimit: 20000000 },
  EG: { currency: 'EGP', primaryRail: 'SWIFT',          secondaryRail: null,        dailyLimit: 50000, monthlyLimit: 200000 },

  // Asia-Pacific
  IN: { currency: 'INR', primaryRail: 'IMPS',           secondaryRail: 'NEFT',      dailyLimit: 200000, monthlyLimit: 1000000 },
  CN: { currency: 'CNY', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 50000, monthlyLimit: 200000 },
  AU: { currency: 'AUD', primaryRail: 'NPP',             secondaryRail: 'SWIFT',     dailyLimit: 10000, monthlyLimit: 50000 },
  JP: { currency: 'JPY', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 1000000, monthlyLimit: 5000000 },
  SG: { currency: 'SGD', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 10000, monthlyLimit: 50000 },
  PH: { currency: 'PHP', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 200000, monthlyLimit: 1000000 },
  MY: { currency: 'MYR', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 30000, monthlyLimit: 150000 },

  // Middle East
  AE: { currency: 'AED', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 30000, monthlyLimit: 150000 },
  SA: { currency: 'SAR', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 30000, monthlyLimit: 150000 },

  // Latin America
  BR: { currency: 'BRL', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 20000, monthlyLimit: 100000 },
  AR: { currency: 'ARS', primaryRail: 'SWIFT',           secondaryRail: null,        dailyLimit: 20000, monthlyLimit: 100000 },
};

// Default fallback for countries not explicitly mapped
const DEFAULT_CONFIG = {
  currency: 'USD', primaryRail: 'SWIFT', secondaryRail: null, dailyLimit: 5000, monthlyLimit: 25000
};

const countryWalletService = {
  /**
   * Get country config for a given ISO alpha-2 country code.
   */
  getCountryConfig(countryCode) {
    return COUNTRY_CONFIG[countryCode?.toUpperCase()] || DEFAULT_CONFIG;
  },

  /**
   * Bootstrap wallet for a new user based on their country.
   * Creates wallet + initial currency entry.
   * Called from auth service after user creation.
   */
  async bootstrapUserWallet(userId, countryCode) {
    const config = countryWalletService.getCountryConfig(countryCode);

    // Create the wallet with the country's primary currency
    const wallet = await Wallet.create(userId, config.currency);

    // Add the primary currency with zero balance
    await Wallet.addCurrency(wallet.id, config.currency);

    // Store country config against wallet in metadata
    await db('wallets')
      .where({ id: wallet.id })
      .update({
        metadata: JSON.stringify({
          country_code: countryCode?.toUpperCase() || 'US',
          primary_rail: config.primaryRail,
          secondary_rail: config.secondaryRail,
          daily_limit: config.dailyLimit,
          monthly_limit: config.monthlyLimit,
        }),
      });

    return {
      wallet,
      currency: config.currency,
      primaryRail: config.primaryRail,
      secondaryRail: config.secondaryRail,
    };
  },

  /**
   * Check if a user's transaction would exceed their daily/monthly limit.
   */
  async checkTransactionLimits(userId, amount, currencyCode) {
    const wallet = await Wallet.findByUserId(userId);
    if (!wallet) throw ApiError.notFound('Wallet not found');

    let metadata = {};
    try { metadata = JSON.parse(wallet.metadata || '{}'); } catch (_) {}

    const dailyLimit = metadata.daily_limit || DEFAULT_CONFIG.dailyLimit;
    const monthlyLimit = metadata.monthly_limit || DEFAULT_CONFIG.monthlyLimit;

    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [dailyTotals, monthlyTotals] = await Promise.all([
      db('transactions')
        .where({ wallet_id: wallet.id, currency_code: currencyCode })
        .whereIn('type', ['send', 'transfer'])
        .where('created_at', '>=', startOfDay)
        .sum('amount as total')
        .first(),
      db('transactions')
        .where({ wallet_id: wallet.id, currency_code: currencyCode })
        .whereIn('type', ['send', 'transfer'])
        .where('created_at', '>=', startOfMonth)
        .sum('amount as total')
        .first(),
    ]);

    const dailySpent = parseFloat(dailyTotals?.total || 0);
    const monthlySpent = parseFloat(monthlyTotals?.total || 0);

    if (dailySpent + amount > dailyLimit) {
      throw ApiError.badRequest(
        `Transaction exceeds your daily limit. Daily remaining: ${currencyCode} ${(dailyLimit - dailySpent).toFixed(2)}`
      );
    }

    if (monthlySpent + amount > monthlyLimit) {
      throw ApiError.badRequest(
        `Transaction exceeds your monthly limit. Monthly remaining: ${currencyCode} ${(monthlyLimit - monthlySpent).toFixed(2)}`
      );
    }

    return {
      dailyRemaining: dailyLimit - dailySpent,
      monthlyRemaining: monthlyLimit - monthlySpent,
    };
  },

  /**
   * Return list of all country configs (for onboarding UI).
   */
  getAllCountryConfigs() {
    return Object.entries(COUNTRY_CONFIG).map(([code, config]) => ({
      countryCode: code,
      ...config,
    }));
  },

  COUNTRY_CONFIG,
  DEFAULT_CONFIG,
};

module.exports = countryWalletService;
