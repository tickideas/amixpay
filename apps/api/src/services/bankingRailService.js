/**
 * bankingRailService.js
 * Selects the appropriate banking rail for a transaction based on country/currency,
 * calculates fees, estimates settlement time, and records rail transactions.
 */

const db = require('../db/knex');
const currencyService = require('./currencyService');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');

// Rail definitions: fee structure and settlement time
const RAIL_DEFINITIONS = {
  ACH: {
    name: 'ACH Transfer',
    feeType: 'flat',
    flatFee: 0,
    percentFee: 0,
    settlementHours: 48,
    maxAmount: 1000000,
    currencies: ['USD'],
    regions: ['US'],
  },
  ACH_INSTANT: {
    name: 'ACH Instant / RTP',
    feeType: 'percent',
    flatFee: 0,
    percentFee: 0.005, // 0.5%
    maxPercentFee: 25,  // $25 max
    settlementHours: 0, // Instant
    maxAmount: 100000,
    currencies: ['USD'],
    regions: ['US'],
  },
  SEPA: {
    name: 'SEPA Credit Transfer',
    feeType: 'flat',
    flatFee: 0.25,
    percentFee: 0,
    settlementHours: 24,
    maxAmount: 999999,
    currencies: ['EUR'],
    regions: ['EU', 'EEA'],
  },
  SEPA_INSTANT: {
    name: 'SEPA Instant Credit Transfer',
    feeType: 'flat',
    flatFee: 0.50,
    percentFee: 0,
    settlementHours: 0,
    maxAmount: 100000,
    currencies: ['EUR'],
    regions: ['EU', 'EEA'],
  },
  FPS: {
    name: 'Faster Payments (UK)',
    feeType: 'flat',
    flatFee: 0,
    percentFee: 0,
    settlementHours: 0,
    maxAmount: 250000,
    currencies: ['GBP'],
    regions: ['GB'],
  },
  BACS: {
    name: 'BACS Direct Credit',
    feeType: 'flat',
    flatFee: 0,
    percentFee: 0,
    settlementHours: 72,
    maxAmount: 20000000,
    currencies: ['GBP'],
    regions: ['GB'],
  },
  SWIFT: {
    name: 'SWIFT International Wire',
    feeType: 'flat',
    flatFee: 15,
    percentFee: 0.001, // 0.1% additional
    settlementHours: 48,
    maxAmount: 10000000,
    currencies: null, // All currencies
    regions: null,    // Global
  },
  NEFT: {
    name: 'NEFT (India)',
    feeType: 'tiered',
    tiers: [
      { upTo: 10000,  fee: 2.5 },
      { upTo: 100000, fee: 5 },
      { upTo: 200000, fee: 15 },
      { upTo: Infinity, fee: 25 },
    ],
    settlementHours: 2,
    maxAmount: 5000000,
    currencies: ['INR'],
    regions: ['IN'],
  },
  IMPS: {
    name: 'IMPS (India Instant)',
    feeType: 'tiered',
    tiers: [
      { upTo: 10000,  fee: 5 },
      { upTo: 100000, fee: 10 },
      { upTo: 200000, fee: 15 },
      { upTo: Infinity, fee: 25 },
    ],
    settlementHours: 0,
    maxAmount: 500000,
    currencies: ['INR'],
    regions: ['IN'],
  },
  NPP: {
    name: 'NPP / Osko (Australia)',
    feeType: 'flat',
    flatFee: 0,
    percentFee: 0,
    settlementHours: 0,
    maxAmount: 1000000,
    currencies: ['AUD'],
    regions: ['AU'],
  },
  ETRANSFER: {
    name: 'Interac e-Transfer (Canada)',
    feeType: 'flat',
    flatFee: 1.50,
    percentFee: 0,
    settlementHours: 0,
    maxAmount: 3000,
    currencies: ['CAD'],
    regions: ['CA'],
  },
  NGIP: {
    name: 'NIP / NIBSS Instant Payment (Nigeria)',
    feeType: 'tiered',
    tiers: [
      { upTo: 5000,    fee: 10.75 },
      { upTo: 50000,   fee: 26.88 },
      { upTo: Infinity, fee: 53.75 },
    ],
    settlementHours: 0,
    maxAmount: 10000000,
    currencies: ['NGN'],
    regions: ['NG'],
  },
};

function calculateRailFee(rail, amount) {
  const def = RAIL_DEFINITIONS[rail];
  if (!def) return 0;

  switch (def.feeType) {
    case 'flat':
      return (def.flatFee || 0) + (amount * (def.percentFee || 0));

    case 'percent': {
      const fee = amount * def.percentFee;
      return def.maxPercentFee ? Math.min(fee, def.maxPercentFee) : fee;
    }

    case 'tiered': {
      const tier = def.tiers.find((t) => amount <= t.upTo);
      return tier ? tier.fee : def.tiers[def.tiers.length - 1].fee;
    }

    default:
      return 0;
  }
}

const bankingRailService = {
  /**
   * Get all available rails from the database.
   */
  async getAvailableRails(countryCode, currencyCode) {
    const query = db('banking_rails').where({ active: true });
    if (countryCode) query.where(db.raw('? = ANY(supported_countries)', [countryCode.toUpperCase()]));
    if (currencyCode) query.where(db.raw('? = ANY(supported_currencies)', [currencyCode.toUpperCase()]));
    return query.orderBy('settlement_minutes', 'asc');
  },

  /**
   * Select the best rail for a transfer based on country pair and currency.
   * Returns the recommended rail code + fee estimate.
   */
  async selectRail({ fromCountry, toCountry, currency, amount, preferInstant = true }) {
    const isSameCountry = fromCountry === toCountry;
    const fromConfig = RAIL_DEFINITIONS;

    // If same country, use domestic rail
    if (isSameCountry) {
      const domesticRails = {
        US: preferInstant ? 'ACH_INSTANT' : 'ACH',
        GB: preferInstant ? 'FPS' : 'BACS',
        DE: preferInstant ? 'SEPA_INSTANT' : 'SEPA',
        FR: preferInstant ? 'SEPA_INSTANT' : 'SEPA',
        IN: preferInstant ? 'IMPS' : 'NEFT',
        AU: 'NPP',
        CA: 'ETRANSFER',
        NG: 'NGIP',
      };
      const rail = domesticRails[fromCountry] || 'SWIFT';
      const fee = calculateRailFee(rail, amount);
      const def = RAIL_DEFINITIONS[rail];
      return {
        rail,
        railName: def?.name || rail,
        fee: parseFloat(fee.toFixed(2)),
        feeCurrency: currency,
        settlementTime: def?.settlementHours === 0 ? 'Instant' : `${def?.settlementHours}h`,
        isInstant: def?.settlementHours === 0,
      };
    }

    // International: use SWIFT
    const fee = calculateRailFee('SWIFT', amount);
    return {
      rail: 'SWIFT',
      railName: 'SWIFT International Wire',
      fee: parseFloat(fee.toFixed(2)),
      feeCurrency: currency,
      settlementTime: '1-3 business days',
      isInstant: false,
    };
  },

  /**
   * Calculate full transfer quote including:
   * - Rail fee
   * - Currency conversion (if cross-currency)
   * - Exchange rate
   * - Receive amount
   */
  async getTransferQuote({ fromCurrency, toCurrency, fromCountry, toCountry, amount, preferInstant = true }) {
    const railInfo = await bankingRailService.selectRail({
      fromCountry, toCountry, currency: fromCurrency, amount, preferInstant,
    });

    let receiveAmount = amount - railInfo.fee;
    let exchangeRate = 1;
    let conversionFee = 0;

    if (fromCurrency !== toCurrency) {
      const conv = await currencyService.convert(receiveAmount, fromCurrency, toCurrency);
      exchangeRate = conv.rate;
      conversionFee = parseFloat((conv.amount * 0.005).toFixed(8)); // 0.5% spread
      receiveAmount = parseFloat((conv.amount - conversionFee).toFixed(8));
    }

    return {
      rail: railInfo.rail,
      railName: railInfo.railName,
      sendAmount: amount,
      sendCurrency: fromCurrency,
      railFee: railInfo.fee,
      conversionFee,
      totalFee: parseFloat((railInfo.fee + conversionFee).toFixed(8)),
      exchangeRate,
      receiveAmount: Math.max(0, receiveAmount),
      receiveCurrency: toCurrency,
      settlementTime: railInfo.settlementTime,
      isInstant: railInfo.isInstant,
    };
  },

  /**
   * Record a banking rail transaction in the database.
   */
  async recordTransaction({
    userId,
    walletId,
    railCode,
    type,
    amount,
    currency,
    status = 'pending',
    externalRef,
    metadata = {},
  }) {
    const reference = externalRef || `RAIL-${uuidv4().split('-')[0].toUpperCase()}`;
    const [row] = await db('banking_transactions').insert({
      user_id: userId,
      wallet_id: walletId,
      rail_code: railCode,
      type,
      amount,
      currency_code: currency,
      status,
      reference,
      metadata: JSON.stringify(metadata),
    }).returning('*');
    return row;
  },

  /**
   * Get banking transaction history for a user.
   */
  async getTransactionHistory(userId, { limit = 20, offset = 0 } = {}) {
    const rows = await db('banking_transactions')
      .where({ user_id: userId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
    const { count } = await db('banking_transactions').where({ user_id: userId }).count('* as count').first();
    return { transactions: rows, total: parseInt(count), limit, offset };
  },

  RAIL_DEFINITIONS,
  calculateRailFee,
};

module.exports = bankingRailService;
