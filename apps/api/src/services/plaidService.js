const { PlaidApi, PlaidEnvironments, Configuration } = require('plaid');
const ApiError = require('../utils/ApiError');

const getPlaidClient = () => {
  const clientId = process.env.PLAID_CLIENT_ID;
  const secret = process.env.PLAID_SECRET;
  const env = process.env.PLAID_ENV || 'sandbox';

  if (!clientId || !secret) {
    throw new Error('Plaid credentials not configured');
  }

  const config = new Configuration({
    basePath: PlaidEnvironments[env],
    baseOptions: {
      headers: {
        'PLAID-CLIENT-ID': clientId,
        'PLAID-SECRET': secret,
      },
    },
  });

  return new PlaidApi(config);
};

const plaidService = {
  async createLinkToken(userId) {
    const client = getPlaidClient();
    const response = await client.linkTokenCreate({
      user: { client_user_id: userId },
      client_name: 'AmixPay',
      products: ['auth', 'transactions'],
      country_codes: ['US', 'GB', 'CA'],
      language: 'en',
    });
    return response.data;
  },

  async exchangePublicToken(publicToken) {
    const client = getPlaidClient();
    const response = await client.itemPublicTokenExchange({ public_token: publicToken });
    return response.data; // { access_token, item_id }
  },

  async getAccounts(accessToken) {
    const client = getPlaidClient();
    const response = await client.accountsGet({ access_token: accessToken });
    return response.data.accounts;
  },

  async getAuthData(accessToken) {
    const client = getPlaidClient();
    const response = await client.authGet({ access_token: accessToken });
    return response.data;
  },

  async getTransactions(accessToken, startDate, endDate) {
    const client = getPlaidClient();
    const response = await client.transactionsGet({
      access_token: accessToken,
      start_date: startDate,
      end_date: endDate,
    });
    return response.data;
  },
};

module.exports = plaidService;
