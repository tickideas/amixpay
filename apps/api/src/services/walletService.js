const db = require('../db/knex');
const Wallet = require('../db/models/Wallet');
const Transaction = require('../db/models/Transaction');
const Ledger = require('../db/models/Ledger');
const ApiError = require('../utils/ApiError');

const SUPPORTED_CURRENCIES = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'NGN', 'KES', 'GHS', 'ZAR'];

const walletService = {
  async getOrCreateWallet(userId, preferredCurrency = 'USD') {
    const currency = SUPPORTED_CURRENCIES.includes(preferredCurrency) ? preferredCurrency : 'USD';
    let wallet = await Wallet.findByUserId(userId);
    if (!wallet) {
      wallet = await Wallet.create(userId, currency);
      await Wallet.addCurrency(wallet.id, currency, 0); // color_index 0 = teal (primary)
    }
    return Wallet.getFullWallet(userId);
  },

  async addCurrency(userId, currencyCode, colorIndex = null) {
    if (!SUPPORTED_CURRENCIES.includes(currencyCode.toUpperCase())) {
      throw ApiError.badRequest(`Currency ${currencyCode} not supported`);
    }
    const wallet = await Wallet.findByUserId(userId);
    if (!wallet) throw ApiError.notFound('Wallet not found');
    const existing = await Wallet.getCurrency(wallet.id, currencyCode.toUpperCase());
    if (existing) throw ApiError.conflict('Currency already added to wallet');
    // Auto-assign next sequential color if none provided
    if (colorIndex === null) {
      const currencies = await Wallet.getCurrencies(wallet.id);
      colorIndex = currencies.length % 8;
    }
    return Wallet.addCurrency(wallet.id, currencyCode.toUpperCase(), colorIndex);
  },

  async removeCurrency(userId, currencyCode) {
    const wallet = await Wallet.findByUserId(userId);
    if (!wallet) throw ApiError.notFound('Wallet not found');
    const wc = await Wallet.getCurrency(wallet.id, currencyCode.toUpperCase());
    if (!wc) throw ApiError.notFound('Currency not in wallet');
    if (parseFloat(wc.balance) !== 0) {
      throw ApiError.badRequest('Cannot remove currency with non-zero balance');
    }
    if (wallet.primary_currency === currencyCode.toUpperCase()) {
      throw ApiError.badRequest('Cannot remove primary currency');
    }
    await Wallet.removeCurrency(wallet.id, currencyCode.toUpperCase());
    return { removed: currencyCode.toUpperCase() };
  },

  async getTransactions(userId, options = {}) {
    const wallet = await Wallet.findByUserId(userId);
    if (!wallet) throw ApiError.notFound('Wallet not found');
    const { limit = 20, offset = 0, type, status, currency } = options;
    const [items, total] = await Promise.all([
      Transaction.listByWallet(wallet.id, { limit, offset, type, status, currency }),
      Transaction.countByWallet(wallet.id),
    ]);
    return { items, total: parseInt(total.count), limit, offset };
  },

  async getTransaction(userId, transactionId) {
    const wallet = await Wallet.findByUserId(userId);
    const txn = await Transaction.findById(transactionId);
    if (!txn || txn.wallet_id !== wallet.id) throw ApiError.notFound('Transaction not found');
    return txn;
  },

  async creditWallet(trx, { walletId, currencyCode, amount, transactionId }) {
    const wc = await trx('wallet_currencies')
      .where({ wallet_id: walletId, currency_code: currencyCode })
      .forUpdate()
      .first();

    if (!wc) {
      // Auto-create currency slot
      const [newWc] = await trx('wallet_currencies')
        .insert({ wallet_id: walletId, currency_code: currencyCode, balance: 0, available_balance: 0, pending_balance: 0 })
        .returning('*');
      const newBal = parseFloat(amount);
      await trx('wallet_currencies').where({ id: newWc.id }).update({ balance: newBal, available_balance: newBal });
      await trx('ledger_entries').insert({ transaction_id: transactionId, wallet_currency_id: newWc.id, entry_type: 'credit', amount, balance_after: newBal });
      return newBal;
    }

    const newBal = parseFloat(wc.balance) + parseFloat(amount);
    await trx('wallet_currencies').where({ id: wc.id }).update({ balance: newBal, available_balance: newBal, updated_at: trx.fn.now() });
    await trx('ledger_entries').insert({ transaction_id: transactionId, wallet_currency_id: wc.id, entry_type: 'credit', amount, balance_after: newBal });
    return newBal;
  },

  async debitWallet(trx, { walletId, currencyCode, amount, transactionId }) {
    const wc = await trx('wallet_currencies')
      .where({ wallet_id: walletId, currency_code: currencyCode })
      .forUpdate()
      .first();

    if (!wc || parseFloat(wc.available_balance) < parseFloat(amount)) {
      throw new Error('INSUFFICIENT_FUNDS');
    }

    const newBal = parseFloat(wc.balance) - parseFloat(amount);
    await trx('wallet_currencies').where({ id: wc.id }).update({ balance: newBal, available_balance: newBal, updated_at: trx.fn.now() });
    await trx('ledger_entries').insert({ transaction_id: transactionId, wallet_currency_id: wc.id, entry_type: 'debit', amount, balance_after: newBal });
    return newBal;
  },

  supportedCurrencies: () => SUPPORTED_CURRENCIES,
};

module.exports = walletService;
