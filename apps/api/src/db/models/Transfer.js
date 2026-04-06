const db = require('../knex');

const Transfer = {
  create: (data) =>
    db('international_transfers').insert(data).returning('*').then((r) => r[0]),

  findById: (id) => db('international_transfers').where({ id }).first(),

  findByWiseId: (wiseTransferId) =>
    db('international_transfers').where({ wise_transfer_id: wiseTransferId }).first(),

  update: (id, data) =>
    db('international_transfers')
      .where({ id })
      .update({ ...data, updated_at: db.fn.now() })
      .returning('*')
      .then((r) => r[0]),

  listByUser: (userId, { limit = 20, offset = 0 } = {}) =>
    db('international_transfers')
      .where({ user_id: userId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset),
};

module.exports = Transfer;
