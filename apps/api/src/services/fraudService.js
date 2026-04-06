const db = require('../db/knex');
const { redisIncr, redisExpire, redisExists, redisSet } = require('../redis/client');
const ApiError = require('../utils/ApiError');

const RULES = {
  LARGE_AMOUNT: { threshold: 10000, severity: 'high', description: 'Transaction exceeds $10,000 threshold' },
  VELOCITY_5MIN: { maxTx: 5, window: 300, severity: 'medium', description: 'More than 5 transactions in 5 minutes' },
  VELOCITY_1HR: { maxTx: 20, window: 3600, severity: 'medium', description: 'More than 20 transactions in 1 hour' },
  DAILY_LIMIT: { maxAmount: 50000, severity: 'high', description: 'Daily transfer limit exceeded' },
  NEW_RECIPIENT: { severity: 'low', description: 'First-time transfer to this recipient' },
};

const fraudService = {
  async evaluateTransaction({ userId, amount, currencyCode, recipientId, transactionId, ipAddress }) {
    const flags = [];
    let riskScore = 0;

    // Rule 1: Large amount
    const amountUSD = currencyCode === 'USD' ? amount : amount; // TODO: convert to USD
    if (parseFloat(amountUSD) >= RULES.LARGE_AMOUNT.threshold) {
      flags.push({ rule: 'LARGE_AMOUNT', severity: 'high' });
      riskScore += 40;
    }

    // Rule 2: Velocity — 5-min window
    const vel5Key = `fraud:vel5:${userId}`;
    const vel5Count = await redisIncr(vel5Key);
    if (vel5Count === 1) await redisExpire(vel5Key, RULES.VELOCITY_5MIN.window);
    if (vel5Count > RULES.VELOCITY_5MIN.maxTx) {
      flags.push({ rule: 'VELOCITY_5MIN', severity: 'medium' });
      riskScore += 30;
    }

    // Rule 3: Velocity — 1-hr window
    const vel1hKey = `fraud:vel1h:${userId}`;
    const vel1hCount = await redisIncr(vel1hKey);
    if (vel1hCount === 1) await redisExpire(vel1hKey, RULES.VELOCITY_1HR.window);
    if (vel1hCount > RULES.VELOCITY_1HR.maxTx) {
      flags.push({ rule: 'VELOCITY_1HR', severity: 'medium' });
      riskScore += 20;
    }

    // Rule 4: Blacklisted user
    const blacklistKey = `fraud:blacklist:${userId}`;
    const isBlacklisted = await redisExists(blacklistKey);
    if (isBlacklisted) {
      flags.push({ rule: 'BLACKLISTED_USER', severity: 'critical' });
      riskScore = 100;
    }

    // Rule 5: First-time recipient
    if (recipientId) {
      const prevTx = await db('payments')
        .where({ sender_id: userId, recipient_id: recipientId })
        .whereNot({ status: 'failed' })
        .count('id as count')
        .first();
      if (parseInt(prevTx.count) === 0) {
        flags.push({ rule: 'NEW_RECIPIENT', severity: 'low' });
        riskScore += 10;
      }
    }

    // Create fraud alert if threshold exceeded
    if (riskScore >= 40 && transactionId) {
      await fraudService.createAlert({
        userId,
        transactionId,
        riskScore,
        flags,
      });
    }

    return { riskScore, flags, shouldBlock: riskScore >= 100, requiresReview: riskScore >= 70 };
  },

  async createAlert({ userId, transactionId, riskScore, flags }) {
    const topFlag = flags.sort((a, b) => {
      const order = { critical: 4, high: 3, medium: 2, low: 1 };
      return order[b.severity] - order[a.severity];
    })[0];

    return db('fraud_alerts').insert({
      user_id: userId,
      transaction_id: transactionId,
      severity: topFlag?.severity || 'low',
      rule_triggered: topFlag?.rule || 'UNKNOWN',
      description: RULES[topFlag?.rule]?.description || 'Suspicious activity detected',
      risk_score: riskScore,
      metadata: JSON.stringify({ flags }),
    }).returning('*').then((r) => r[0]);
  },

  async listAlerts({ limit = 20, offset = 0, status, severity }) {
    const q = db('fraud_alerts')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
    if (status) q.where({ status });
    if (severity) q.where({ severity });
    return q;
  },

  async getAlert(alertId) {
    return db('fraud_alerts').where({ id: alertId }).first();
  },

  async reviewAlert(alertId, adminId, { status, notes }) {
    return db('fraud_alerts')
      .where({ id: alertId })
      .update({ status, reviewed_by: adminId, review_notes: notes, reviewed_at: db.fn.now() })
      .returning('*')
      .then((r) => r[0]);
  },

  async blockUser(userId) {
    await redisSet(`fraud:blacklist:${userId}`, '1', 86400 * 30); // 30 days
    await db('users').where({ id: userId }).update({ status: 'suspended' });
  },
};

module.exports = fraudService;
