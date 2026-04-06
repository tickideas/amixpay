const db = require('../knex');

const Merchant = {
  findByUserId: (userId) => db('merchants').where({ user_id: userId }).first(),
  findById: (id) => db('merchants').where({ id }).first(),

  create: (data) => db('merchants').insert(data).returning('*').then((r) => r[0]),

  update: (id, data) =>
    db('merchants').where({ id }).update({ ...data, updated_at: db.fn.now() }).returning('*').then((r) => r[0]),

  listPayments: (merchantId, { limit = 20, offset = 0, status } = {}) => {
    const q = db('merchant_payments')
      .where({ merchant_id: merchantId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
    if (status) q.where({ status });
    return q;
  },

  createPayment: (data) => db('merchant_payments').insert(data).returning('*').then((r) => r[0]),

  stats: async (merchantId) => {
    const [total, recent] = await Promise.all([
      db('merchant_payments')
        .where({ merchant_id: merchantId, status: 'completed' })
        .sum('amount as total')
        .count('id as count')
        .first(),
      db('merchant_payments')
        .where({ merchant_id: merchantId })
        .orderBy('created_at', 'desc')
        .limit(5),
    ]);
    return { total, recent };
  },

  createCheckoutLink: (data) => db('checkout_links').insert(data).returning('*').then((r) => r[0]),
  findCheckoutLink: (slug) => db('checkout_links').where({ slug, active: true }).first(),
};

module.exports = Merchant;
