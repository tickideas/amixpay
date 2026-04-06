const db = require('../knex');
const { v4: uuidv4 } = require('uuid');

const Transaction = {
  create: (data) =>
    db('transactions')
      .insert({ ...data, reference_id: data.reference_id || `TXN-${uuidv4()}` })
      .returning('*')
      .then((r) => r[0]),

  findById: (id) => db('transactions').where({ id }).first(),

  findByReference: (referenceId) =>
    db('transactions').where({ reference_id: referenceId }).first(),

  updateStatus: (id, status) =>
    db('transactions')
      .where({ id })
      .update({ status, updated_at: db.fn.now() })
      .returning('*')
      .then((r) => r[0]),

  listByWallet: (walletId, { limit = 20, offset = 0, type, status, currency } = {}) => {
    const q = db('transactions')
      .where({ wallet_id: walletId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
    if (type) q.where({ type });
    if (status) q.where({ status });
    if (currency) q.where({ currency_code: currency });
    return q;
  },

  countByWallet: (walletId) =>
    db('transactions').where({ wallet_id: walletId }).count('id as count').first(),
};

module.exports = Transaction;
