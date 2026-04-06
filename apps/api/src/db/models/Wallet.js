const db = require('../knex');

const Wallet = {
  findByUserId: (userId) =>
    db('wallets').where({ user_id: userId }).first(),

  findById: (id) =>
    db('wallets').where({ id }).first(),

  create: (userId, primaryCurrency = 'USD') =>
    db('wallets')
      .insert({ user_id: userId, primary_currency: primaryCurrency })
      .returning('*')
      .then((r) => r[0]),

  update: (id, data) =>
    db('wallets').where({ id }).update(data).returning('*').then((r) => r[0]),

  getCurrencies: (walletId) =>
    db('wallet_currencies').where({ wallet_id: walletId }),

  getCurrency: (walletId, currencyCode) =>
    db('wallet_currencies').where({ wallet_id: walletId, currency_code: currencyCode }).first(),

  addCurrency: (walletId, currencyCode, colorIndex = null) =>
    db('wallet_currencies')
      .insert({ wallet_id: walletId, currency_code: currencyCode, color_index: colorIndex })
      .onConflict(['wallet_id', 'currency_code'])
      .ignore()
      .returning('*')
      .then((r) => r[0]),

  removeCurrency: (walletId, currencyCode) =>
    db('wallet_currencies')
      .where({ wallet_id: walletId, currency_code: currencyCode })
      .delete(),

  getFullWallet: async (userId) => {
    const wallet = await db('wallets').where({ user_id: userId }).first();
    if (!wallet) return null;
    const currencies = await db('wallet_currencies').where({ wallet_id: wallet.id });
    return { ...wallet, currencies };
  },
};

module.exports = Wallet;
