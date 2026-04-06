const db = require('../knex');

const Notification = {
  create: (data) =>
    db('notifications').insert(data).returning('*').then((r) => r[0]),

  findById: (id) => db('notifications').where({ id }).first(),

  listByUser: (userId, { limit = 20, offset = 0, unreadOnly = false } = {}) => {
    const q = db('notifications')
      .where({ user_id: userId })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
    if (unreadOnly) q.where({ read: false });
    return q;
  },

  markRead: (id, userId) =>
    db('notifications')
      .where({ id, user_id: userId })
      .update({ read: true, read_at: db.fn.now() })
      .returning('*')
      .then((r) => r[0]),

  markAllRead: (userId) =>
    db('notifications')
      .where({ user_id: userId, read: false })
      .update({ read: true, read_at: db.fn.now() }),

  countUnread: (userId) =>
    db('notifications').where({ user_id: userId, read: false }).count('id as count').first(),

  getPreferences: (userId) =>
    db('notification_preferences').where({ user_id: userId }).first(),

  upsertPreferences: (userId, prefs) =>
    db('notification_preferences')
      .insert({ user_id: userId, ...prefs })
      .onConflict('user_id')
      .merge(prefs)
      .returning('*')
      .then((r) => r[0]),
};

module.exports = Notification;
