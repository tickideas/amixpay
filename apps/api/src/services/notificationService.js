const db = require('../db/knex');
const Notification = require('../db/models/Notification');
const axios = require('axios');

const notificationService = {
  async create({ userId, type, title, body, data = {} }) {
    const notification = await Notification.create({ user_id: userId, type, title, body, data: JSON.stringify(data) });

    // Fire push notification (non-blocking)
    notificationService._sendPush(userId, { title, body, data }).catch(() => {});

    return notification;
  },

  async _sendPush(userId, { title, body, data }) {
    const prefs = await Notification.getPreferences(userId);
    if (prefs && !prefs.push_enabled) return;

    const devices = await db('user_devices').where({ user_id: userId });
    if (!devices.length) return;

    const fcmKey = process.env.FIREBASE_SERVER_KEY;
    if (!fcmKey) return;

    const tokens = devices.map((d) => d.device_token);
    await axios.post(
      'https://fcm.googleapis.com/fcm/send',
      {
        registration_ids: tokens,
        notification: { title, body },
        data,
      },
      { headers: { Authorization: `key=${fcmKey}`, 'Content-Type': 'application/json' } }
    ).catch((e) => console.error('[FCM] Push error:', e.message));
  },

  async list(userId, options = {}) {
    return Notification.listByUser(userId, options);
  },

  async markRead(notificationId, userId) {
    const notif = await Notification.markRead(notificationId, userId);
    if (!notif) throw new Error('Notification not found');
    return notif;
  },

  async markAllRead(userId) {
    return Notification.markAllRead(userId);
  },

  async getPreferences(userId) {
    return Notification.getPreferences(userId);
  },

  async updatePreferences(userId, prefs) {
    return Notification.upsertPreferences(userId, prefs);
  },

  async registerDevice(userId, { deviceToken, platform, deviceName }) {
    return db('user_devices')
      .insert({ user_id: userId, device_token: deviceToken, platform, device_name: deviceName, last_active_at: db.fn.now() })
      .onConflict(['user_id', 'device_token'])
      .merge({ last_active_at: db.fn.now() })
      .returning('*')
      .then((r) => r[0]);
  },

  async countUnread(userId) {
    const result = await Notification.countUnread(userId);
    return parseInt(result.count);
  },
};

module.exports = notificationService;
