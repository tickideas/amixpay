const db = require('../knex');

const VirtualCard = {
  create: (data) => db('virtual_cards').insert(data).returning('*').then((r) => r[0]),
  findById: (id) => db('virtual_cards').where({ id }).first(),
  findByStripeId: (stripeCardId) => db('virtual_cards').where({ stripe_card_id: stripeCardId }).first(),
  listByUser: (userId) => db('virtual_cards').where({ user_id: userId }).orderBy('created_at', 'desc'),
  update: (id, data) =>
    db('virtual_cards').where({ id }).update({ ...data, updated_at: db.fn.now() }).returning('*').then((r) => r[0]),
};

module.exports = VirtualCard;
