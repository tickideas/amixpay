const db = require('../db/knex');
const Merchant = require('../db/models/Merchant');
const stripeService = require('./stripeService');
const ApiError = require('../utils/ApiError');
const { v4: uuidv4 } = require('uuid');
const User = require('../db/models/User');

const merchantService = {
  async register(userId, { businessName, businessType, websiteUrl, supportEmail }) {
    const existing = await Merchant.findByUserId(userId);
    if (existing) throw ApiError.conflict('User already has a merchant account');

    // Create Stripe Connect account
    let stripeAccountId = null;
    try {
      const user = await User.findById(userId);
      const account = await stripeService.createConnectAccount(user);
      stripeAccountId = account.id;
    } catch (e) {
      console.warn('[Merchant] Stripe Connect failed:', e.message);
    }

    const merchant = await Merchant.create({
      user_id: userId,
      business_name: businessName,
      business_type: businessType,
      website_url: websiteUrl,
      support_email: supportEmail,
      stripe_account_id: stripeAccountId,
    });

    // Elevate user role to merchant
    await User.update(userId, { role: 'merchant' });
    return merchant;
  },

  async getDashboard(userId) {
    const merchant = await Merchant.findByUserId(userId);
    if (!merchant) throw ApiError.notFound('Merchant account not found');
    const stats = await Merchant.stats(merchant.id);
    return { merchant, stats };
  },

  async update(userId, data) {
    const merchant = await Merchant.findByUserId(userId);
    if (!merchant) throw ApiError.notFound('Merchant account not found');
    return Merchant.update(merchant.id, data);
  },

  async createPayment(merchantId, { payerId, amount, currencyCode, description, checkoutLinkId }) {
    return Merchant.createPayment({
      merchant_id: merchantId,
      payer_id: payerId,
      amount,
      currency_code: currencyCode,
      description,
      reference_id: `MPY-${uuidv4()}`,
      checkout_link_id: checkoutLinkId,
      status: 'pending',
    });
  },

  async listPayments(userId, options) {
    const merchant = await Merchant.findByUserId(userId);
    if (!merchant) throw ApiError.notFound('Merchant account not found');
    return Merchant.listPayments(merchant.id, options);
  },

  async createCheckoutLink(userId, { amount, fixedAmount, currencyCode, title, description, expiresAt }) {
    const merchant = await Merchant.findByUserId(userId);
    if (!merchant) throw ApiError.notFound('Merchant account not found');
    const slug = uuidv4().replace(/-/g, '').substring(0, 12);
    return Merchant.createCheckoutLink({
      merchant_id: merchant.id,
      slug,
      amount,
      fixed_amount: fixedAmount,
      currency_code: currencyCode,
      title,
      description,
      expires_at: expiresAt,
    });
  },

  async getCheckoutLink(slug) {
    const link = await Merchant.findCheckoutLink(slug);
    if (!link) throw ApiError.notFound('Checkout link not found or expired');
    if (link.expires_at && new Date(link.expires_at) < new Date()) {
      throw ApiError.badRequest('Checkout link has expired');
    }
    return link;
  },

  async getStripeConnectLink(userId) {
    const merchant = await Merchant.findByUserId(userId);
    if (!merchant) throw ApiError.notFound('Merchant not found');
    if (!merchant.stripe_account_id) throw ApiError.badRequest('Stripe account not set up');

    return stripeService.createAccountLink(merchant.stripe_account_id, {
      refreshUrl: `${process.env.APP_URL}/merchants/stripe/refresh`,
      returnUrl: `${process.env.APP_URL}/merchants/stripe/return`,
    });
  },
};

module.exports = merchantService;
