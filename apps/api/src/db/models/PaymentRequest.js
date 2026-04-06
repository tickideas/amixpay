const db = require('../knex');

const PaymentRequest = {
  create: (data) => db('payment_requests').insert(data).returning('*').then((r) => r[0]),
  findById: (id) => db('payment_requests').where({ id }).first(),
  update: (id, data) =>
    db('payment_requests').where({ id }).update(data).returning('*').then((r) => r[0]),

  listByUser: (userId, { limit = 20, offset = 0, role = 'all' } = {}) => {
    const q = db('payment_requests').orderBy('created_at', 'desc').limit(limit).offset(offset);
    if (role === 'requester') q.where({ requester_id: userId });
    else if (role === 'payer') q.where({ payer_id: userId });
    else q.where('requester_id', userId).orWhere('payer_id', userId);
    return q;
  },

  createSplit: (data) => db('splits').insert(data).returning('*').then((r) => r[0]),
  findSplitById: (id) => db('splits').where({ id }).first(),
  updateSplit: (id, data) => db('splits').where({ id }).update(data).returning('*').then((r) => r[0]),

  createShare: (data) => db('split_shares').insert(data).returning('*').then((r) => r[0]),
  getShares: (splitId) => db('split_shares').where({ split_id: splitId }),
  updateShare: (id, data) => db('split_shares').where({ id }).update(data).returning('*').then((r) => r[0]),

  listSplits: (userId, { limit = 20, offset = 0 } = {}) =>
    db('splits')
      .where({ creator_id: userId })
      .orWhereExists(
        db('split_shares').whereRaw('split_shares.split_id = splits.id').where({ user_id: userId })
      )
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset),
};

module.exports = PaymentRequest;
