const db = require('../knex');

const Ledger = {
  createEntry: (data) =>
    db('ledger_entries').insert(data).returning('*').then((r) => r[0]),

  getByTransaction: (transactionId) =>
    db('ledger_entries').where({ transaction_id: transactionId }),

  getByWalletCurrency: (walletCurrencyId, { limit = 50, offset = 0 } = {}) =>
    db('ledger_entries')
      .where({ wallet_currency_id: walletCurrencyId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset),

  // Atomic debit + credit using a Knex transaction
  transfer: async (trx, { debitWcId, creditWcId, amount, transactionId }) => {
    const debitWc = await trx('wallet_currencies').where({ id: debitWcId }).forUpdate().first();
    const creditWc = await trx('wallet_currencies').where({ id: creditWcId }).forUpdate().first();

    if (!debitWc || parseFloat(debitWc.available_balance) < parseFloat(amount)) {
      throw new Error('INSUFFICIENT_FUNDS');
    }

    const newDebitBalance = parseFloat(debitWc.balance) - parseFloat(amount);
    const newCreditBalance = parseFloat(creditWc.balance) + parseFloat(amount);

    await trx('wallet_currencies')
      .where({ id: debitWcId })
      .update({ balance: newDebitBalance, available_balance: newDebitBalance, updated_at: trx.fn.now() });

    await trx('wallet_currencies')
      .where({ id: creditWcId })
      .update({ balance: newCreditBalance, available_balance: newCreditBalance, updated_at: trx.fn.now() });

    const [debitEntry, creditEntry] = await Promise.all([
      trx('ledger_entries').insert({
        transaction_id: transactionId,
        wallet_currency_id: debitWcId,
        entry_type: 'debit',
        amount,
        balance_after: newDebitBalance,
      }).returning('*').then((r) => r[0]),
      trx('ledger_entries').insert({
        transaction_id: transactionId,
        wallet_currency_id: creditWcId,
        entry_type: 'credit',
        amount,
        balance_after: newCreditBalance,
      }).returning('*').then((r) => r[0]),
    ]);

    return { debitEntry, creditEntry, newDebitBalance, newCreditBalance };
  },
};

module.exports = Ledger;
