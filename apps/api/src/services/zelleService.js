/**
 * zelleService.js
 * Handles Zelle-style instant P2P transfers:
 *  - In-network: AmixPay user → AmixPay user (by username/email/phone)
 *  - External US Zelle: AmixPay user → Zelle-enrolled US email/phone (stubbed — real Zelle integration requires bank partnership)
 *
 * All in-network transfers are atomic using PostgreSQL transactions.
 */

const db = require('../db/knex');
const Wallet = require('../db/models/Wallet');
const User = require('../db/models/User');
const walletService = require('./walletService');
const countryWalletService = require('./countryWalletService');
const currencyService = require('./currencyService');
const notificationService = require('./notificationService');
const fraudService = require('./fraudService');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');
const { redisGet, redisSet } = require('../redis/client');

const ZELLE_FEE_RATE = 0; // Zelle-style = no fee for in-network
const ZELLE_MAX_SINGLE_USD = 2500; // $2,500 per transaction cap
const ZELLE_MAX_DAILY_USD = 5000;  // $5,000/day cap

/**
 * Resolve a recipient by username, email, or phone number.
 */
async function resolveRecipient(identifier) {
  if (!identifier) return null;
  const clean = identifier.trim().toLowerCase();
  // Try email
  if (clean.includes('@')) return User.findByEmail(clean);
  // Try phone (digits only)
  if (/^\+?[\d\s\-().]{7,15}$/.test(identifier)) return User.findByPhone(identifier.replace(/\D/g, ''));
  // Try username (strip @ prefix)
  return User.findByUsername(clean.replace(/^@/, ''));
}

const zelleService = {
  /**
   * Look up a recipient by identifier (for the send flow "confirm recipient" step).
   * Returns safe public profile data only.
   */
  async lookupRecipient(identifier) {
    const user = await resolveRecipient(identifier);
    if (!user) return null;
    return {
      id: user.id,
      username: user.username,
      firstName: user.first_name,
      lastName: user.last_name,
      avatar: user.avatar_url,
      isVerified: user.kyc_status === 'approved',
    };
  },

  /**
   * Send an instant in-network Zelle-style transfer.
   * Handles same-currency and cross-currency (auto-converts).
   */
  async sendInNetwork({ senderId, identifier, amount, currencyCode, note, deviceId }) {
    if (!amount || amount <= 0) throw ApiError.badRequest('Amount must be greater than 0');
    if (amount > ZELLE_MAX_SINGLE_USD * 2) throw ApiError.badRequest(`Single transfer limit is USD ${ZELLE_MAX_SINGLE_USD}`);

    const recipient = await resolveRecipient(identifier);
    if (!recipient) throw ApiError.notFound('Recipient not found on AmixPay');
    if (recipient.id === senderId) throw ApiError.badRequest('Cannot send money to yourself');
    if (recipient.status !== 'active') throw ApiError.forbidden('Recipient account is not active');

    const [senderWallet, recipientWallet] = await Promise.all([
      Wallet.findByUserId(senderId),
      Wallet.findByUserId(recipient.id),
    ]);
    if (!senderWallet) throw ApiError.notFound('Your wallet not found');
    if (!recipientWallet) throw ApiError.notFound('Recipient wallet not found');

    const sender = await User.findById(senderId);

    // Fraud check
    const { riskScore: fraudScore } = await fraudService.evaluateTransaction({
      userId: senderId,
      amount,
      currencyCode,
      recipientId,
    });
    if (fraudScore >= 80) throw ApiError.forbidden('Transaction flagged by fraud detection. Please contact support.');

    // Check sender transaction limits
    await countryWalletService.checkTransactionLimits(senderId, amount, currencyCode);

    // Determine recipient receive currency
    // If recipient has the sender's currency, use it. Otherwise, use recipient's primary currency and convert.
    const recipientCurrencyRow = await Wallet.getCurrency(recipientWallet.id, currencyCode);
    const recipientCurrency = recipientCurrencyRow
      ? currencyCode
      : (await db('wallet_currencies').where({ wallet_id: recipientWallet.id }).orderBy('created_at', 'asc').first())?.currency_code || currencyCode;

    let receiveAmount = amount;
    let exchangeRate = 1;
    let conversionFee = 0;

    if (recipientCurrency !== currencyCode) {
      const conversion = await currencyService.convert(amount, currencyCode, recipientCurrency);
      receiveAmount = parseFloat(conversion.amount.toFixed(8));
      exchangeRate = conversion.rate;
      conversionFee = parseFloat(conversion.fee.toFixed(8));
      receiveAmount -= conversionFee; // Fee deducted from received amount
    }

    const reference = `ZEL-${uuidv4().split('-')[0].toUpperCase()}-${Date.now().toString(36).toUpperCase()}`;

    const result = await db.transaction(async (trx) => {
      // Debit sender
      await walletService.debitWallet(trx, {
        walletId: senderWallet.id,
        currencyCode,
        amount,
        transactionId: null, // Will be linked below
      });

      // If recipient doesn't have the required currency wallet, add it
      if (!recipientCurrencyRow && currencyCode === recipientCurrency) {
        await trx('wallet_currencies').insert({
          wallet_id: recipientWallet.id,
          currency_code: recipientCurrency,
          balance: 0,
          available_balance: 0,
        }).onConflict(['wallet_id', 'currency_code']).ignore();
      }

      // Credit recipient
      await walletService.creditWallet(trx, {
        walletId: recipientWallet.id,
        currencyCode: recipientCurrency,
        amount: receiveAmount,
        transactionId: null,
      });

      // Record in zelle_transfers table
      const [zelleTransfer] = await trx('zelle_transfers').insert({
        sender_wallet_id: senderWallet.id,
        recipient_wallet_id: recipientWallet.id,
        sender_id: senderId,
        recipient_id: recipient.id,
        send_amount: amount,
        send_currency: currencyCode,
        receive_amount: receiveAmount,
        receive_currency: recipientCurrency,
        exchange_rate: exchangeRate,
        conversion_fee: conversionFee,
        total_fee: conversionFee,
        note: note || null,
        reference,
        status: 'completed',
        transfer_type: 'in_network',
        fraud_score: fraudScore,
      }).returning('*');

      // Sender transaction record
      const [senderTxn] = await trx('transactions').insert({
        wallet_id: senderWallet.id,
        type: 'send',
        status: 'completed',
        amount,
        currency_code: currencyCode,
        fee_amount: conversionFee,
        fee_currency: currencyCode,
        reference_id: reference,
        description: note || `Zelle to ${recipient.first_name} ${recipient.last_name}`,
        counterparty_user_id: recipient.id,
        counterparty_name: `${recipient.first_name} ${recipient.last_name}`,
        metadata: JSON.stringify({ zelleTransferId: zelleTransfer.id, type: 'zelle_send' }),
      }).returning('*');

      // Recipient transaction record
      const [recipientTxn] = await trx('transactions').insert({
        wallet_id: recipientWallet.id,
        type: 'receive',
        status: 'completed',
        amount: receiveAmount,
        currency_code: recipientCurrency,
        fee_amount: 0,
        reference_id: `${reference}-RCV`,
        description: note || `Zelle from ${sender.first_name} ${sender.last_name}`,
        counterparty_user_id: senderId,
        counterparty_name: `${sender.first_name} ${sender.last_name}`,
        metadata: JSON.stringify({ zelleTransferId: zelleTransfer.id, type: 'zelle_receive' }),
      }).returning('*');

      return { zelleTransfer, senderTxn, recipientTxn };
    });

    // Notifications (fire and forget)
    notificationService.create({
      userId: recipient.id,
      type: 'zelle_received',
      title: 'Money Received',
      body: `${sender.first_name} ${sender.last_name} sent you ${recipientCurrency} ${receiveAmount.toFixed(2)} via AmixPay`,
      data: { reference, amount: receiveAmount, currency: recipientCurrency },
    }).catch(() => {});

    return {
      reference,
      status: 'completed',
      sendAmount: amount,
      sendCurrency: currencyCode,
      receiveAmount,
      receiveCurrency: recipientCurrency,
      exchangeRate,
      conversionFee,
      recipient: {
        id: recipient.id,
        username: recipient.username,
        firstName: recipient.first_name,
        lastName: recipient.last_name,
      },
      transferId: result.zelleTransfer.id,
    };
  },

  /**
   * External Zelle transfer (US users to enrolled US Zelle recipients).
   * In production this requires a bank partner API (Early Warning Services).
   * This implementation stubs the external call and records the attempt.
   */
  async sendExternal({ senderId, recipientPhone, recipientEmail, amount, note, deviceId }) {
    if (!recipientPhone && !recipientEmail) throw ApiError.badRequest('Phone or email required for external Zelle');

    const sender = await User.findById(senderId);
    if (!sender) throw ApiError.notFound('Sender not found');
    if (sender.country_code !== 'US') throw ApiError.badRequest('External Zelle transfers are only available for US accounts');

    const wallet = await Wallet.findByUserId(senderId);
    if (!wallet) throw ApiError.notFound('Wallet not found');

    if (amount > ZELLE_MAX_SINGLE_USD) throw ApiError.badRequest(`Max single Zelle transfer is $${ZELLE_MAX_SINGLE_USD}`);

    // Check daily limit
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const { total: dailyTotal } = await db('zelle_transfers')
      .where({ sender_id: senderId, transfer_type: 'external' })
      .where('created_at', '>=', today)
      .sum('send_amount as total')
      .first();

    if ((parseFloat(dailyTotal) || 0) + amount > ZELLE_MAX_DAILY_USD) {
      throw ApiError.badRequest(`Daily Zelle limit of $${ZELLE_MAX_DAILY_USD} exceeded`);
    }

    const { riskScore: fraudScore } = await fraudService.evaluateTransaction({
      userId: senderId, amount, currencyCode: 'USD',
    });
    if (fraudScore >= 75) throw ApiError.forbidden('Transaction flagged. Please contact support.');

    const reference = `EXT-ZEL-${uuidv4().split('-')[0].toUpperCase()}`;

    // In production: call bank partner Zelle API here
    // const zelleApiResult = await externalZelleApi.send({ ... });
    // For now, record as 'pending' — bank will confirm via webhook
    const externalStatus = 'pending';

    await db.transaction(async (trx) => {
      // Debit sender wallet
      await walletService.debitWallet(trx, {
        walletId: wallet.id,
        currencyCode: 'USD',
        amount,
        transactionId: null,
      });

      await trx('zelle_transfers').insert({
        sender_wallet_id: wallet.id,
        recipient_wallet_id: null, // External — no AmixPay wallet
        sender_id: senderId,
        recipient_id: null,
        send_amount: amount,
        send_currency: 'USD',
        receive_amount: amount,
        receive_currency: 'USD',
        exchange_rate: 1,
        conversion_fee: 0,
        total_fee: 0,
        note: note || null,
        reference,
        status: externalStatus,
        transfer_type: 'external',
        fraud_score: fraudScore,
        external_recipient_phone: recipientPhone || null,
        external_recipient_email: recipientEmail || null,
      });

      await trx('transactions').insert({
        wallet_id: wallet.id,
        type: 'send',
        status: externalStatus,
        amount,
        currency_code: 'USD',
        fee_amount: 0,
        reference_id: reference,
        description: note || `External Zelle to ${recipientEmail || recipientPhone}`,
        metadata: JSON.stringify({ type: 'zelle_external', recipient: recipientEmail || recipientPhone }),
      });
    });

    return {
      reference,
      status: externalStatus,
      amount,
      currency: 'USD',
      recipient: { email: recipientEmail, phone: recipientPhone },
      message: 'Transfer submitted. The recipient will receive a Zelle notification to claim the funds within 1-3 business days.',
    };
  },

  /**
   * Get Zelle transfer history for a user.
   */
  async getHistory(userId, { limit = 20, offset = 0, type } = {}) {
    let query = db('zelle_transfers')
      .where(function () {
        this.where('sender_id', userId).orWhere('recipient_id', userId);
      })
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);

    if (type) query = query.where({ transfer_type: type });

    const transfers = await query;
    const total = await db('zelle_transfers')
      .where(function () {
        this.where('sender_id', userId).orWhere('recipient_id', userId);
      })
      .count('* as count')
      .first();

    return { transfers, total: parseInt(total.count), limit, offset };
  },
};

module.exports = zelleService;
