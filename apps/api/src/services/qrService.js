const QRCode = require('qrcode');
const db = require('../db/knex');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');

const qrService = {
  async generate({ userId, username, amount, currency, description }) {
    const codeId = uuidv4();
    const payload = JSON.stringify({
      app: 'amixpay',
      version: '1',
      to: username,
      userId,
      amount: amount || null,
      currency: currency || 'USD',
      description: description || null,
      codeId,
    });

    // Generate QR as base64 data URL
    const dataUrl = await QRCode.toDataURL(payload, {
      errorCorrectionLevel: 'H',
      margin: 2,
      color: { dark: '#0D6B5E', light: '#FFFFFF' },
      width: 300,
    });

    // Store in DB
    await db('qr_codes').insert({
      id: codeId,
      user_id: userId,
      payload,
      amount: amount || null,
      currency: currency || 'USD',
      description,
      active: true,
    }).onConflict('id').ignore();

    return { codeId, dataUrl, payload: JSON.parse(payload) };
  },

  async parse(rawPayload) {
    try {
      const data = JSON.parse(rawPayload);
      if (data.app !== 'amixpay') throw new Error('Not an AmixPay QR code');
      return { valid: true, data };
    } catch {
      return { valid: false, error: 'Invalid QR code' };
    }
  },

  async listMyCodes(userId) {
    try {
      return db('qr_codes').where({ user_id: userId, active: true }).orderBy('created_at', 'desc');
    } catch {
      return [];
    }
  },

  async deactivate(codeId, userId) {
    const updated = await db('qr_codes')
      .where({ id: codeId, user_id: userId })
      .update({ active: false })
      .returning('*');
    if (!updated.length) throw ApiError.notFound('QR code not found');
    return updated[0];
  },
};

// Ensure qr_codes table exists (created lazily if migrations haven't run yet)
const ensureQrTable = async () => {
  try {
    const exists = await db.schema.hasTable('qr_codes');
    if (!exists) {
      await db.schema.createTable('qr_codes', (t) => {
        t.uuid('id').primary();
        t.uuid('user_id').references('id').inTable('users').onDelete('CASCADE');
        t.text('payload');
        t.decimal('amount', 20, 8);
        t.string('currency', 3);
        t.text('description');
        t.boolean('active').defaultTo(true);
        t.timestamp('created_at').defaultTo(db.fn.now());
      });
    }
  } catch (_) {}
};

module.exports = qrService;
