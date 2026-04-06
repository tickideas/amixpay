const axios = require('axios');
const crypto = require('crypto');
const ApiError = require('../utils/ApiError');

// ---------------------------------------------------------------------------
// Flutterwave Service — Server-Side Only
//
// SECRET KEY and ENCRYPTION KEY live here exclusively.
// The Flutter app only ever sees the public key.
// ---------------------------------------------------------------------------

const BASE_URL = 'https://api.flutterwave.com/v3';

const getHeaders = () => {
  const secretKey = process.env.FLW_SECRET_KEY;
  if (!secretKey) throw new Error('FLW_SECRET_KEY not configured');
  return {
    Authorization: `Bearer ${secretKey}`,
    'Content-Type': 'application/json',
  };
};

const flutterwaveService = {
  // ── Webhook signature verification ─────────────────────────────────────
  verifyWebhookSignature(payload, signatureHeader) {
    const hash = process.env.FLW_WEBHOOK_HASH;
    if (!hash) throw new ApiError(500, 'FLW_WEBHOOK_HASH not configured');
    if (signatureHeader !== hash) {
      throw new ApiError(401, 'Invalid Flutterwave webhook signature');
    }
    return true;
  },

  // ── Verify a transaction by ID (called after Flutter SDK returns txId) ──
  async verifyTransaction(transactionId) {
    const response = await axios.get(
      `${BASE_URL}/transactions/${transactionId}/verify`,
      { headers: getHeaders() }
    );

    if (response.data.status !== 'success') {
      throw new ApiError(400, 'Flutterwave transaction verification failed');
    }

    const txData = response.data.data;
    return {
      id: txData.id,
      txRef: txData.tx_ref,
      amount: parseFloat(txData.charged_amount),
      currency: txData.currency,
      status: txData.status,        // "successful" | "failed"
      paymentType: txData.payment_type,
      customerEmail: txData.customer?.email,
      customerPhone: txData.customer?.phone_number,
      createdAt: txData.created_at,
    };
  },

  // ── Initiate a payout (for merchant settlement or user withdraw) ────────
  async initiatePayout({ accountNumber, bankCode, amount, currency, narration, reference }) {
    const response = await axios.post(
      `${BASE_URL}/transfers`,
      {
        account_bank: bankCode,
        account_number: accountNumber,
        amount,
        currency,
        narration: narration || 'AmixPay withdrawal',
        reference,
        debit_currency: currency,
        callback_url: process.env.FLW_CALLBACK_URL || 'https://api.amixpay.com/v1/flutterwave/webhooks',
      },
      { headers: getHeaders() }
    );

    if (response.data.status !== 'success') {
      throw new ApiError(400, `Payout initiation failed: ${response.data.message}`);
    }

    return response.data.data;
  },

  // ── Get supported banks for a country ──────────────────────────────────
  async getBanks(country = 'NG') {
    const response = await axios.get(
      `${BASE_URL}/banks/${country}`,
      { headers: getHeaders() }
    );
    return response.data.data || [];
  },

  // ── Get transfer fee estimate ───────────────────────────────────────────
  async getTransferFee({ amount, currency, type = 'account' }) {
    const response = await axios.get(
      `${BASE_URL}/transfers/fee?amount=${amount}&currency=${currency}&type=${type}`,
      { headers: getHeaders() }
    );
    return response.data.data;
  },

  // ── Get exchange rates ──────────────────────────────────────────────────
  async getRate({ from, to, amount }) {
    const response = await axios.get(
      `${BASE_URL}/transfers/rates?amount=${amount}&destination_currency=${to}&source_currency=${from}`,
      { headers: getHeaders() }
    );
    return response.data.data;
  },
};

module.exports = flutterwaveService;
