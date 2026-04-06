const axios = require('axios');
const db = require('../db/knex');
const Transfer = require('../db/models/Transfer');
const Wallet = require('../db/models/Wallet');
const Transaction = require('../db/models/Transaction');
const walletService = require('./walletService');
const currencyService = require('./currencyService');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');

const wiseClient = axios.create({
  baseURL: process.env.WISE_API_URL || 'https://api.sandbox.transferwise.tech',
  headers: { Authorization: `Bearer ${process.env.WISE_API_KEY || ''}` },
  timeout: 10000,
});

const SUPPORTED_COUNTRIES = [
  { code: 'US', name: 'United States', currency: 'USD' },
  { code: 'GB', name: 'United Kingdom', currency: 'GBP' },
  { code: 'EU', name: 'European Union', currency: 'EUR' },
  { code: 'NG', name: 'Nigeria', currency: 'NGN' },
  { code: 'KE', name: 'Kenya', currency: 'KES' },
  { code: 'GH', name: 'Ghana', currency: 'GHS' },
  { code: 'ZA', name: 'South Africa', currency: 'ZAR' },
  { code: 'CA', name: 'Canada', currency: 'CAD' },
  { code: 'AU', name: 'Australia', currency: 'AUD' },
  { code: 'IN', name: 'India', currency: 'INR' },
];

const transferService = {
  async createQuote({ userId, sourceCurrency, targetCurrency, sourceAmount }) {
    // Try Wise API first, fall back to our own rates
    try {
      const profileId = process.env.WISE_PROFILE_ID;
      const { data } = await wiseClient.post(`/v3/profiles/${profileId}/quotes`, {
        sourceCurrency,
        targetCurrency,
        sourceAmount,
        targetAmount: null,
        payOut: 'BANK_TRANSFER',
        paymentMetadata: { transferNature: 'MOVING_MONEY_BETWEEN_OWN_ACCOUNTS' },
      });
      return {
        quoteId: data.id,
        sourceCurrency,
        targetCurrency,
        sourceAmount,
        targetAmount: data.rate * sourceAmount,
        rate: data.rate,
        fee: data.paymentOptions?.[0]?.fee?.total || 0,
        estimatedDelivery: data.paymentOptions?.[0]?.estimatedDelivery,
        provider: 'wise',
      };
    } catch (err) {
      // Fallback to internal currency service
      const { amount, rate, fee } = await currencyService.convert(sourceAmount, sourceCurrency, targetCurrency);
      return {
        quoteId: `LOCAL-${uuidv4()}`,
        sourceCurrency,
        targetCurrency,
        sourceAmount,
        targetAmount: amount,
        rate,
        fee,
        estimatedDelivery: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
        provider: 'internal',
      };
    }
  },

  async createTransfer({ userId, quoteId, sourceAmount, sourceCurrency, targetCurrency, targetAmount, rate, fee, recipientDetails }) {
    const senderWallet = await Wallet.findByUserId(userId);
    if (!senderWallet) throw ApiError.notFound('Wallet not found');

    const totalDebit = parseFloat(sourceAmount) + parseFloat(fee);
    const referenceId = `TRF-${uuidv4()}`;

    const result = await db.transaction(async (trx) => {
      const txn = await trx('transactions').insert({
        wallet_id: senderWallet.id,
        type: 'international_transfer',
        status: 'pending',
        amount: sourceAmount,
        currency_code: sourceCurrency,
        fee_amount: fee,
        fee_currency: sourceCurrency,
        exchange_rate: rate,
        reference_id: referenceId,
        description: `International transfer to ${recipientDetails.name} (${targetCurrency})`,
        metadata: JSON.stringify({ targetAmount, targetCurrency }),
      }).returning('*').then((r) => r[0]);

      // Debit sender wallet
      await walletService.debitWallet(trx, {
        walletId: senderWallet.id,
        currencyCode: sourceCurrency,
        amount: totalDebit,
        transactionId: txn.id,
      });

      // Create transfer record
      const transfer = await trx('international_transfers').insert({
        user_id: userId,
        transaction_id: txn.id,
        source_amount: sourceAmount,
        source_currency: sourceCurrency,
        target_amount: targetAmount,
        target_currency: targetCurrency,
        exchange_rate: rate,
        fee_amount: fee,
        wise_quote_id: quoteId,
        status: 'pending',
        recipient_name: recipientDetails.name,
        recipient_account_number: recipientDetails.accountNumber,
        recipient_routing_number: recipientDetails.routingNumber,
        recipient_iban: recipientDetails.iban,
        recipient_bic: recipientDetails.bic,
        recipient_bank_name: recipientDetails.bankName,
        recipient_country: recipientDetails.country,
        purpose: recipientDetails.purpose,
      }).returning('*').then((r) => r[0]);

      await trx('transactions').where({ id: txn.id }).update({ status: 'processing' });

      return { transfer, txn };
    });

    // Attempt Wise submission (async, non-blocking)
    transferService._submitToWise(result.transfer.id).catch((e) =>
      console.error('[Transfer] Wise submission failed:', e.message)
    );

    return result;
  },

  async _submitToWise(transferId) {
    const transfer = await Transfer.findById(transferId);
    if (!transfer || !transfer.wise_quote_id || transfer.wise_quote_id.startsWith('LOCAL-')) return;

    try {
      const profileId = process.env.WISE_PROFILE_ID;
      const { data } = await wiseClient.post('/v1/transfers', {
        targetAccount: transfer.wise_recipient_id,
        quoteUuid: transfer.wise_quote_id,
        customerTransactionId: transferId,
        details: { reference: `AMIXPAY-${transferId}`, transferPurpose: transfer.purpose },
      });
      await Transfer.update(transferId, { wise_transfer_id: data.id, status: 'processing' });
    } catch (err) {
      console.error('[Transfer] Wise API error:', err.response?.data || err.message);
    }
  },

  async getTransfer(userId, transferId) {
    const transfer = await Transfer.findById(transferId);
    if (!transfer || transfer.user_id !== userId) throw ApiError.notFound('Transfer not found');
    return transfer;
  },

  async listTransfers(userId, options = {}) {
    return Transfer.listByUser(userId, options);
  },

  getSupportedCountries: () => SUPPORTED_COUNTRIES,
};

module.exports = transferService;
