const db = require('../knex');
const { v4: uuidv4 } = require('uuid');

const Payment = {
  create: (data) =>
    db('payments')
      .insert({ ...data, reference_id: data.reference_id || `PAY-${uuidv4()}` })
      .returning('*')
      .then((r) => r[0]),

  findById: (id) => db('payments').where({ id }).first(),

  update: (id, data) =>
    db('payments').where({ id }).update(data).returning('*').then((r) => r[0]),

  listBySender: (senderId, { limit = 20, offset = 0 } = {}) =>
    db('payments')
      .where({ sender_id: senderId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset),

  listByRecipient: (recipientId, { limit = 20, offset = 0 } = {}) =>
    db('payments')
      .where({ recipient_id: recipientId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset),
};

module.exports = Payment;
