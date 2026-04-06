const db = require('../db/knex');
const User = require('../db/models/User');
const ApiError = require('../utils/ApiError');

const KYC_LEVELS = {
  0: { name: 'Unverified', dailyLimit: 500, description: 'Email only' },
  1: { name: 'Basic', dailyLimit: 2000, description: 'Phone verified' },
  2: { name: 'Standard', dailyLimit: 10000, description: 'ID document verified' },
  3: { name: 'Enhanced', dailyLimit: 100000, description: 'Full KYC with selfie' },
};

const kycService = {
  async submitDocument(userId, { type, s3Key }) {
    const validTypes = ['national_id', 'passport', 'drivers_license', 'utility_bill', 'selfie'];
    if (!validTypes.includes(type)) throw ApiError.badRequest('Invalid document type');

    const user = await User.findById(userId);
    if (!user) throw ApiError.notFound('User not found');

    // Check if document already submitted for review
    const existing = await db('kyc_documents')
      .where({ user_id: userId, type, status: 'pending' })
      .first();
    if (existing) throw ApiError.conflict('Document of this type already under review');

    const doc = await db('kyc_documents')
      .insert({ user_id: userId, type, s3_key: s3Key })
      .returning('*')
      .then((r) => r[0]);

    // Auto-advance KYC status to pending if it's 'none'
    if (user.kyc_status === 'none') {
      await User.update(userId, { kyc_status: 'pending' });
    }

    return doc;
  },

  async getStatus(userId) {
    const user = await User.findById(userId);
    if (!user) throw ApiError.notFound('User not found');

    const documents = await db('kyc_documents').where({ user_id: userId }).orderBy('created_at', 'desc');
    const levelInfo = KYC_LEVELS[user.kyc_level];

    return {
      status: user.kyc_status,
      level: user.kyc_level,
      levelName: levelInfo.name,
      dailyLimit: levelInfo.dailyLimit,
      documents: documents.map((d) => ({
        id: d.id,
        type: d.type,
        status: d.status,
        submittedAt: d.created_at,
        rejectionReason: d.rejection_reason,
      })),
    };
  },

  async approveDocument(documentId, { level }) {
    const doc = await db('kyc_documents').where({ id: documentId }).first();
    if (!doc) throw ApiError.notFound('Document not found');

    await db('kyc_documents')
      .where({ id: documentId })
      .update({ status: 'approved', updated_at: db.fn.now() });

    // Update user KYC level and status
    await User.update(doc.user_id, {
      kyc_status: 'approved',
      kyc_level: Math.max(level || 1, (await User.findById(doc.user_id)).kyc_level),
    });

    return { documentId, approved: true };
  },

  async rejectDocument(documentId, reason) {
    const doc = await db('kyc_documents').where({ id: documentId }).first();
    if (!doc) throw ApiError.notFound('Document not found');

    await db('kyc_documents')
      .where({ id: documentId })
      .update({ status: 'rejected', rejection_reason: reason, updated_at: db.fn.now() });

    // If no approved docs remain, mark as rejected
    const approvedCount = await db('kyc_documents')
      .where({ user_id: doc.user_id, status: 'approved' })
      .count('id as count')
      .first();

    if (parseInt(approvedCount.count) === 0) {
      await User.update(doc.user_id, { kyc_status: 'rejected' });
    }

    return { documentId, rejected: true, reason };
  },

  getLevels: () => KYC_LEVELS,
};

module.exports = kycService;
