const db = require('../db/knex');
const Wallet = require('../db/models/Wallet');
const Transaction = require('../db/models/Transaction');
const Payment = require('../db/models/Payment');
const PaymentRequest = require('../db/models/PaymentRequest');
const User = require('../db/models/User');
const walletService = require('./walletService');
const notificationService = require('./notificationService');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');

const FEE_RATE = 0.005; // 0.5% fee

const paymentService = {
  async send({ senderId, recipientIdentifier, amount, currencyCode, note }) {
    const recipient = await User.findByIdentifier(recipientIdentifier);
    if (!recipient) throw ApiError.notFound('Recipient not found');
    if (recipient.id === senderId) throw ApiError.badRequest('Cannot send money to yourself');
    if (recipient.status !== 'active') throw ApiError.badRequest('Recipient account is not active');

    const [senderWallet, recipientWallet] = await Promise.all([
      Wallet.findByUserId(senderId),
      Wallet.findByUserId(recipient.id),
    ]);
    if (!senderWallet) throw ApiError.notFound('Sender wallet not found');
    if (!recipientWallet) throw ApiError.notFound('Recipient wallet not found');

    const fee = parseFloat((amount * FEE_RATE).toFixed(8));
    const totalDebit = parseFloat(amount) + fee;
    const referenceId = `PAY-${uuidv4()}`;

    const result = await db.transaction(async (trx) => {
      // Create transaction records
      const senderTxn = await trx('transactions').insert({
        wallet_id: senderWallet.id,
        type: 'send',
        status: 'pending',
        amount,
        currency_code: currencyCode,
        fee_amount: fee,
        fee_currency: currencyCode,
        reference_id: referenceId,
        description: note || `Payment to ${recipient.username}`,
        counterparty_user_id: recipient.id,
        counterparty_name: `${recipient.first_name} ${recipient.last_name}`,
      }).returning('*').then((r) => r[0]);

      const recipientTxn = await trx('transactions').insert({
        wallet_id: recipientWallet.id,
        type: 'receive',
        status: 'pending',
        amount,
        currency_code: currencyCode,
        fee_amount: 0,
        reference_id: `${referenceId}-RCV`,
        description: note || `Payment from ${(await User.findById(senderId)).username}`,
        counterparty_user_id: senderId,
      }).returning('*').then((r) => r[0]);

      // Debit sender (amount + fee)
      await walletService.debitWallet(trx, {
        walletId: senderWallet.id,
        currencyCode,
        amount: totalDebit,
        transactionId: senderTxn.id,
      });

      // Credit recipient (amount only)
      await walletService.creditWallet(trx, {
        walletId: recipientWallet.id,
        currencyCode,
        amount,
        transactionId: recipientTxn.id,
      });

      // Create payment record
      const payment = await trx('payments').insert({
        sender_id: senderId,
        recipient_id: recipient.id,
        sender_transaction_id: senderTxn.id,
        recipient_transaction_id: recipientTxn.id,
        amount,
        currency_code: currencyCode,
        fee_amount: fee,
        status: 'completed',
        reference_id: referenceId,
        note,
      }).returning('*').then((r) => r[0]);

      // Update transaction statuses
      await trx('transactions').whereIn('id', [senderTxn.id, recipientTxn.id]).update({ status: 'completed' });

      return { payment, senderTxn, recipientTxn };
    });

    // Send notifications (non-blocking)
    const sender = await User.findById(senderId);
    notificationService.create({
      userId: recipient.id,
      type: 'payment_received',
      title: 'Payment Received',
      body: `You received ${currencyCode} ${amount} from ${sender.first_name} ${sender.last_name}`,
      data: { paymentId: result.payment.id, amount, currency: currencyCode },
    }).catch(() => {});

    return result;
  },

  async createRequest({ requesterId, payerIdentifier, amount, currencyCode, note }) {
    const payer = await User.findByIdentifier(payerIdentifier);
    if (!payer) throw ApiError.notFound('Payer not found');
    if (payer.id === requesterId) throw ApiError.badRequest('Cannot request money from yourself');

    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    const request = await PaymentRequest.create({
      requester_id: requesterId,
      payer_id: payer.id,
      amount,
      currency_code: currencyCode,
      note,
      expires_at: expiresAt,
    });

    const requester = await User.findById(requesterId);
    notificationService.create({
      userId: payer.id,
      type: 'payment_request',
      title: 'Payment Request',
      body: `${requester.first_name} ${requester.last_name} is requesting ${currencyCode} ${amount}`,
      data: { requestId: request.id },
    }).catch(() => {});

    return request;
  },

  async acceptRequest(requestId, payerId) {
    const request = await PaymentRequest.findById(requestId);
    if (!request) throw ApiError.notFound('Payment request not found');
    if (request.payer_id !== payerId) throw ApiError.forbidden('Not authorized');
    if (request.status !== 'pending') throw ApiError.badRequest(`Request is already ${request.status}`);
    if (new Date(request.expires_at) < new Date()) {
      await PaymentRequest.update(requestId, { status: 'expired' });
      throw ApiError.badRequest('Payment request has expired');
    }

    const result = await paymentService.send({
      senderId: payerId,
      recipientIdentifier: (await User.findById(request.requester_id)).email,
      amount: request.amount,
      currencyCode: request.currency_code,
      note: request.note,
    });

    await PaymentRequest.update(requestId, { status: 'accepted', payment_id: result.payment.id });
    return { request: { ...request, status: 'accepted' }, payment: result.payment };
  },

  async declineRequest(requestId, payerId) {
    const request = await PaymentRequest.findById(requestId);
    if (!request) throw ApiError.notFound('Payment request not found');
    if (request.payer_id !== payerId) throw ApiError.forbidden('Not authorized');
    if (request.status !== 'pending') throw ApiError.badRequest(`Request is already ${request.status}`);
    return PaymentRequest.update(requestId, { status: 'declined' });
  },

  async createSplit({ creatorId, participantIds, title, items, taxAmount = 0, discountAmount = 0, currencyCode }) {
    const totalAmount = items.reduce((sum, i) => sum + parseFloat(i.price) * i.qty, 0) + parseFloat(taxAmount) - parseFloat(discountAmount);
    const shareAmount = parseFloat((totalAmount / (participantIds.length + 1)).toFixed(8));

    const split = await PaymentRequest.createSplit({
      creator_id: creatorId,
      title,
      total_amount: totalAmount,
      currency_code: currencyCode,
      items: JSON.stringify(items),
      tax_amount: taxAmount,
      discount_amount: discountAmount,
    });

    // Create shares for all participants (not creator)
    await Promise.all(participantIds.map((uid) =>
      PaymentRequest.createShare({ split_id: split.id, user_id: uid, amount: shareAmount })
    ));

    return { split, shareAmount };
  },
};

module.exports = paymentService;
