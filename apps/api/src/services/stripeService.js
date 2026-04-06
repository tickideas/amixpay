const Stripe = require('stripe');
const ApiError = require('../utils/ApiError');

const getStripe = () => {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) throw new Error('STRIPE_SECRET_KEY not configured');
  return Stripe(key);
};

const stripeService = {
  async createOrGetCustomer(user) {
    const stripe = getStripe();
    if (user.stripe_customer_id) {
      return stripe.customers.retrieve(user.stripe_customer_id);
    }
    return stripe.customers.create({
      email: user.email,
      name: `${user.first_name} ${user.last_name}`,
      metadata: { amixpay_user_id: user.id },
    });
  },

  async createPaymentIntent({ amount, currency, customerId, metadata = {} }) {
    const stripe = getStripe();
    // Stripe amounts are in smallest unit (cents for USD)
    const amountCents = Math.round(parseFloat(amount) * 100);
    return stripe.paymentIntents.create({
      amount: amountCents,
      currency: currency.toLowerCase(),
      customer: customerId,
      metadata,
      automatic_payment_methods: { enabled: true },
    });
  },

  async confirmPaymentIntent(paymentIntentId) {
    const stripe = getStripe();
    return stripe.paymentIntents.retrieve(paymentIntentId);
  },

  async createVirtualCard({ customerId, cardHolderName, currency = 'usd', spendingLimit }) {
    const stripe = getStripe();
    // Stripe Issuing
    const cardholder = await stripe.issuing.cardholders.create({
      type: 'individual',
      name: cardHolderName,
      email: `cardholder_${Date.now()}@amixpay.internal`,
      billing: {
        address: {
          line1: '123 AmixPay St',
          city: 'San Francisco',
          state: 'CA',
          postal_code: '94105',
          country: 'US',
        },
      },
    });

    const cardParams = {
      cardholder: cardholder.id,
      currency,
      type: 'virtual',
    };

    if (spendingLimit) {
      cardParams.spending_controls = {
        spending_limits: [{ amount: Math.round(spendingLimit * 100), interval: 'monthly' }],
      };
    }

    return stripe.issuing.cards.create(cardParams);
  },

  async updateCard(stripeCardId, { status, spendingLimit }) {
    const stripe = getStripe();
    const updates = {};
    if (status) updates.status = status; // 'active' | 'inactive' | 'canceled'
    if (spendingLimit) {
      updates.spending_controls = {
        spending_limits: [{ amount: Math.round(spendingLimit * 100), interval: 'monthly' }],
      };
    }
    return stripe.issuing.cards.update(stripeCardId, updates);
  },

  async retrieveCardDetails(stripeCardId) {
    const stripe = getStripe();
    return stripe.issuing.cards.retrieve(stripeCardId, { expand: ['number', 'cvc'] });
  },

  verifyWebhookSignature(payload, sig) {
    const stripe = getStripe();
    const secret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!secret) throw new Error('STRIPE_WEBHOOK_SECRET not configured');
    return stripe.webhooks.constructEvent(payload, sig, secret);
  },

  async createConnectAccount(user) {
    const stripe = getStripe();
    return stripe.accounts.create({
      type: 'express',
      email: user.email,
      capabilities: { transfers: { requested: true } },
      metadata: { amixpay_user_id: user.id },
    });
  },

  async createAccountLink(accountId, { refreshUrl, returnUrl }) {
    const stripe = getStripe();
    return stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: 'account_onboarding',
    });
  },
};

module.exports = stripeService;
