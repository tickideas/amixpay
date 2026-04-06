const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

exports.seed = async (knex) => {
  // Clean in reverse dependency order
  await knex('ledger_entries').del();
  await knex('transactions').del();
  await knex('wallet_currencies').del();
  await knex('wallets').del();
  await knex('users').del();

  const hashedPassword = await bcrypt.hash('Password123!', 12);

  const userId1 = uuidv4();
  const userId2 = uuidv4();
  const adminId = uuidv4();

  // Create users
  await knex('users').insert([
    {
      id: userId1,
      username: 'alice',
      email: 'alice@amixpay.dev',
      phone: '+14155551234',
      password_hash: hashedPassword,
      first_name: 'Alice',
      last_name: 'Johnson',
      country_code: 'US',
      kyc_status: 'approved',
      kyc_level: 2,
      status: 'active',
      email_verified: true,
      phone_verified: true,
      role: 'user',
    },
    {
      id: userId2,
      username: 'bob',
      email: 'bob@amixpay.dev',
      phone: '+14155555678',
      password_hash: hashedPassword,
      first_name: 'Bob',
      last_name: 'Smith',
      country_code: 'GB',
      kyc_status: 'approved',
      kyc_level: 2,
      status: 'active',
      email_verified: true,
      phone_verified: true,
      role: 'user',
    },
    {
      id: adminId,
      username: 'admin',
      email: 'admin@amixpay.dev',
      phone: '+14155559999',
      password_hash: hashedPassword,
      first_name: 'Admin',
      last_name: 'AmixPay',
      country_code: 'US',
      kyc_status: 'approved',
      kyc_level: 3,
      status: 'active',
      email_verified: true,
      phone_verified: true,
      role: 'admin',
    },
  ]);

  // Create wallets
  const walletId1 = uuidv4();
  const walletId2 = uuidv4();
  await knex('wallets').insert([
    { id: walletId1, user_id: userId1, primary_currency: 'USD', status: 'active' },
    { id: walletId2, user_id: userId2, primary_currency: 'GBP', status: 'active' },
  ]);

  // Create wallet currencies with balances
  const wc1 = uuidv4();
  const wc2 = uuidv4();
  const wc3 = uuidv4();
  await knex('wallet_currencies').insert([
    { id: wc1, wallet_id: walletId1, currency_code: 'USD', balance: 5000.00, available_balance: 5000.00, pending_balance: 0 },
    { id: wc2, wallet_id: walletId1, currency_code: 'EUR', balance: 1200.00, available_balance: 1200.00, pending_balance: 0 },
    { id: wc3, wallet_id: walletId2, currency_code: 'GBP', balance: 3500.00, available_balance: 3500.00, pending_balance: 0 },
  ]);

  // Seed notification preferences
  await knex('notification_preferences').insert([
    { id: uuidv4(), user_id: userId1, push_enabled: true, sms_enabled: true, email_enabled: true, payment_alerts: true, security_alerts: true },
    { id: uuidv4(), user_id: userId2, push_enabled: true, sms_enabled: false, email_enabled: true, payment_alerts: true, security_alerts: true },
  ]);

  console.log('✅ Seed complete!');
  console.log('');
  console.log('Test accounts:');
  console.log('  alice@amixpay.dev / Password123! (USD wallet: $5,000 + EUR €1,200)');
  console.log('  bob@amixpay.dev   / Password123! (GBP wallet: £3,500)');
  console.log('  admin@amixpay.dev / Password123! (admin role)');
};
