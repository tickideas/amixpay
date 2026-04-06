/**
 * Migration 011 — Zelle-style P2P transfers & Banking Rails
 *
 * New tables:
 *   zelle_transfers      – in-network instant P2P transfer records
 *   banking_rails        – rail config per currency/country pair
 *   banking_transactions – external bank rail transaction log
 *   country_wallet_map   – country → default currency mapping
 */

exports.up = async function (knex) {
  // ── Zelle-style instant transfers ──────────────────────────────────────────
  await knex.schema.createTable('zelle_transfers', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('sender_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.uuid('recipient_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.uuid('sender_wallet_id').notNullable().references('id').inTable('wallets');
    t.uuid('recipient_wallet_id').notNullable().references('id').inTable('wallets');

    // Amounts
    t.decimal('amount', 20, 8).notNullable();
    t.string('currency_code', 10).notNullable();
    t.decimal('fee', 20, 8).notNullable().defaultTo(0);
    t.decimal('amount_received', 20, 8).notNullable(); // amount - fee

    // Conversion (when sender/recipient currencies differ)
    t.string('sender_currency', 10).notNullable();
    t.string('recipient_currency', 10).notNullable();
    t.decimal('exchange_rate', 20, 8).defaultTo(1);
    t.decimal('converted_amount', 20, 8); // amount in recipient currency

    // Transfer metadata
    t.string('reference', 64).unique().notNullable();    // e.g., ZEL-20260316-XXXXXXXX
    t.string('recipient_identifier').notNullable();       // email/phone/username used to find recipient
    t.string('identifier_type', 20).notNullable();       // 'email' | 'phone' | 'username'
    t.text('note');
    t.string('status', 20).notNullable().defaultTo('completed'); // completed | failed | reversed

    // Fraud & compliance
    t.decimal('fraud_score', 5, 2).defaultTo(0);
    t.boolean('is_flagged').defaultTo(false);
    t.string('flagged_reason');

    // Relations to transaction ledger
    t.uuid('sender_transaction_id').references('id').inTable('transactions');
    t.uuid('recipient_transaction_id').references('id').inTable('transactions');

    t.timestamps(true, true);
  });

  // ── Banking rail definitions ────────────────────────────────────────────────
  await knex.schema.createTable('banking_rails', (t) => {
    t.increments('id').primary();
    t.string('rail_code', 20).notNullable().unique(); // ACH | SEPA | SWIFT | FPS | BACS | NPP | ETRANSFER
    t.string('rail_name').notNullable();              // "ACH (US)" | "SEPA Instant" | "SWIFT Wire" | "Faster Payments (UK)"
    t.string('rail_region').notNullable();            // US | EU | UK | GLOBAL | AU | CA | NG | ...

    // Currencies supported by this rail
    t.specificType('supported_currencies', 'TEXT[]').notNullable();

    // Timing
    t.string('settlement_time').notNullable();        // "instant" | "same-day" | "1-3 business days"
    t.integer('settlement_minutes');                   // estimated minutes for automated processing

    // Fees
    t.decimal('flat_fee', 10, 4).notNullable().defaultTo(0);
    t.decimal('percent_fee', 10, 6).notNullable().defaultTo(0);
    t.decimal('min_fee', 10, 4).defaultTo(0);
    t.decimal('max_fee', 10, 4);
    t.decimal('min_amount', 20, 8).defaultTo(0.01);
    t.decimal('max_amount', 20, 8).defaultTo(1000000);

    // Availability
    t.boolean('is_active').defaultTo(true);
    t.boolean('requires_iban').defaultTo(false);
    t.boolean('requires_swift').defaultTo(false);
    t.boolean('requires_routing').defaultTo(false);   // US routing number
    t.boolean('requires_sort_code').defaultTo(false); // UK sort code
    t.boolean('requires_bsb').defaultTo(false);       // Australia BSB
    t.boolean('requires_ifsc').defaultTo(false);      // India IFSC

    t.timestamps(true, true);
  });

  // ── External banking transactions (ACH/SEPA/etc) ───────────────────────────
  await knex.schema.createTable('banking_transactions', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users');
    t.uuid('wallet_id').notNullable().references('id').inTable('wallets');
    t.string('rail_code', 20).notNullable();          // which rail was used
    t.string('direction', 10).notNullable();          // 'inbound' | 'outbound'

    // Amounts
    t.decimal('amount', 20, 8).notNullable();
    t.string('currency_code', 10).notNullable();
    t.decimal('fee', 20, 8).notNullable().defaultTo(0);
    t.decimal('net_amount', 20, 8).notNullable();

    // External reference IDs
    t.string('external_reference');                    // bank/rail reference number
    t.string('ach_trace_number', 30);
    t.string('sepa_end_to_end_id', 40);
    t.string('swift_uetr', 50);
    t.string('fps_payment_id', 50);

    // Recipient bank details (encrypted at rest in production)
    t.string('recipient_name');
    t.string('recipient_account_masked');              // last 4 only
    t.string('recipient_bank_name');
    t.string('recipient_bank_country', 3);

    // Status tracking
    t.string('status', 20).notNullable().defaultTo('pending');
    // pending | processing | completed | failed | returned | reversed
    t.text('status_message');
    t.timestamp('submitted_at');
    t.timestamp('settled_at');
    t.timestamp('expected_settlement_at');

    // Linked wallet transaction
    t.uuid('transaction_id').references('id').inTable('transactions');

    t.timestamps(true, true);
  });

  // ── Country → default currency + rail mapping ──────────────────────────────
  await knex.schema.createTable('country_wallet_map', (t) => {
    t.string('country_code', 3).primary();    // ISO 3166-1 alpha-2
    t.string('country_name').notNullable();
    t.string('default_currency', 10).notNullable();
    t.string('currency_symbol', 10).notNullable();
    t.string('primary_rail', 20);             // default outbound rail
    t.string('secondary_rail', 20);           // fallback
    t.string('flag_emoji', 10);
    t.boolean('is_supported').defaultTo(true);
    t.boolean('kyc_required').defaultTo(false);
    t.decimal('daily_limit', 20, 8).defaultTo(10000);
    t.decimal('monthly_limit', 20, 8).defaultTo(50000);
    t.timestamps(true, true);
  });

  // ── Exchange rate snapshots ────────────────────────────────────────────────
  // Extend existing exchange_rates_cache with provider info if not exists
  const hasRateTable = await knex.schema.hasTable('exchange_rates_cache');
  if (!hasRateTable) {
    await knex.schema.createTable('exchange_rates_cache', (t) => {
      t.increments('id').primary();
      t.string('base_currency', 10).notNullable();
      t.string('quote_currency', 10).notNullable();
      t.decimal('rate', 20, 8).notNullable();
      t.string('provider', 50).defaultTo('internal');
      t.decimal('spread_percent', 8, 4).defaultTo(0.5); // AmixPay markup
      t.timestamp('fetched_at').notNullable().defaultTo(knex.fn.now());
      t.timestamp('expires_at').notNullable();
      t.unique(['base_currency', 'quote_currency', 'provider']);
    });
  }

  // ── Seed banking rails ──────────────────────────────────────────────────────
  await knex('banking_rails').insert([
    {
      rail_code: 'ACH',
      rail_name: 'ACH (US Automated Clearing House)',
      rail_region: 'US',
      supported_currencies: knex.raw("ARRAY['USD']"),
      settlement_time: 'same-day',
      settlement_minutes: 480,
      flat_fee: 0.25,
      percent_fee: 0,
      min_amount: 1,
      max_amount: 10000,
      requires_routing: true,
    },
    {
      rail_code: 'ACH_INSTANT',
      rail_name: 'RTP / ACH Instant',
      rail_region: 'US',
      supported_currencies: knex.raw("ARRAY['USD']"),
      settlement_time: 'instant',
      settlement_minutes: 1,
      flat_fee: 0.50,
      percent_fee: 0,
      min_amount: 1,
      max_amount: 500000,
      requires_routing: true,
    },
    {
      rail_code: 'SEPA',
      rail_name: 'SEPA Credit Transfer',
      rail_region: 'EU',
      supported_currencies: knex.raw("ARRAY['EUR']"),
      settlement_time: '1 business day',
      settlement_minutes: 1440,
      flat_fee: 0,
      percent_fee: 0,
      min_amount: 0.01,
      max_amount: 999999,
      requires_iban: true,
      requires_swift: true,
    },
    {
      rail_code: 'SEPA_INSTANT',
      rail_name: 'SEPA Instant Credit Transfer',
      rail_region: 'EU',
      supported_currencies: knex.raw("ARRAY['EUR']"),
      settlement_time: 'instant',
      settlement_minutes: 1,
      flat_fee: 0.10,
      percent_fee: 0,
      min_amount: 0.01,
      max_amount: 100000,
      requires_iban: true,
      requires_swift: true,
    },
    {
      rail_code: 'FPS',
      rail_name: 'Faster Payments (UK)',
      rail_region: 'UK',
      supported_currencies: knex.raw("ARRAY['GBP']"),
      settlement_time: 'instant',
      settlement_minutes: 2,
      flat_fee: 0,
      percent_fee: 0,
      min_amount: 0.01,
      max_amount: 250000,
      requires_sort_code: true,
    },
    {
      rail_code: 'BACS',
      rail_name: 'BACS Direct Credit (UK)',
      rail_region: 'UK',
      supported_currencies: knex.raw("ARRAY['GBP']"),
      settlement_time: '3 business days',
      settlement_minutes: 4320,
      flat_fee: 0,
      percent_fee: 0,
      min_amount: 0.01,
      max_amount: 20000000,
      requires_sort_code: true,
    },
    {
      rail_code: 'SWIFT',
      rail_name: 'SWIFT Wire Transfer',
      rail_region: 'GLOBAL',
      supported_currencies: knex.raw("ARRAY['USD','EUR','GBP','JPY','CAD','AUD','CHF','CNY','HKD','SGD']"),
      settlement_time: '1-5 business days',
      settlement_minutes: 4320,
      flat_fee: 25.00,
      percent_fee: 0,
      min_amount: 100,
      max_amount: 10000000,
      requires_swift: true,
    },
    {
      rail_code: 'NEFT',
      rail_name: 'NEFT (India National Electronic Funds Transfer)',
      rail_region: 'IN',
      supported_currencies: knex.raw("ARRAY['INR']"),
      settlement_time: 'same-day',
      settlement_minutes: 60,
      flat_fee: 0,
      percent_fee: 0,
      min_amount: 1,
      max_amount: 200000,
      requires_ifsc: true,
    },
    {
      rail_code: 'IMPS',
      rail_name: 'IMPS (India Immediate Payment Service)',
      rail_region: 'IN',
      supported_currencies: knex.raw("ARRAY['INR']"),
      settlement_time: 'instant',
      settlement_minutes: 1,
      flat_fee: 5,
      percent_fee: 0,
      min_amount: 1,
      max_amount: 500000,
      requires_ifsc: true,
    },
    {
      rail_code: 'NPP',
      rail_name: 'NPP (Australia New Payments Platform)',
      rail_region: 'AU',
      supported_currencies: knex.raw("ARRAY['AUD']"),
      settlement_time: 'instant',
      settlement_minutes: 1,
      flat_fee: 0,
      percent_fee: 0,
      min_amount: 0.01,
      max_amount: 1000000,
      requires_bsb: true,
    },
    {
      rail_code: 'ETRANSFER',
      rail_name: 'Interac e-Transfer (Canada)',
      rail_region: 'CA',
      supported_currencies: knex.raw("ARRAY['CAD']"),
      settlement_time: 'instant',
      settlement_minutes: 30,
      flat_fee: 1.50,
      percent_fee: 0,
      min_amount: 0.01,
      max_amount: 3000,
      requires_routing: false,
    },
    {
      rail_code: 'NGIP',
      rail_name: 'NIP (Nigeria Inter-Bank Settlement System)',
      rail_region: 'NG',
      supported_currencies: knex.raw("ARRAY['NGN']"),
      settlement_time: 'instant',
      settlement_minutes: 2,
      flat_fee: 10,
      percent_fee: 0,
      min_amount: 100,
      max_amount: 10000000,
      requires_routing: false,
    },
  ]);

  // ── Seed country wallet map ─────────────────────────────────────────────────
  const countries = [
    { country_code: 'US', country_name: 'United States', default_currency: 'USD', currency_symbol: '$', primary_rail: 'ACH_INSTANT', secondary_rail: 'ACH', flag_emoji: '🇺🇸', daily_limit: 25000, monthly_limit: 100000 },
    { country_code: 'GB', country_name: 'United Kingdom', default_currency: 'GBP', currency_symbol: '£', primary_rail: 'FPS', secondary_rail: 'BACS', flag_emoji: '🇬🇧', daily_limit: 20000, monthly_limit: 85000 },
    { country_code: 'DE', country_name: 'Germany', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇩🇪', daily_limit: 20000, monthly_limit: 85000 },
    { country_code: 'FR', country_name: 'France', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇫🇷', daily_limit: 20000, monthly_limit: 85000 },
    { country_code: 'ES', country_name: 'Spain', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇪🇸' },
    { country_code: 'IT', country_name: 'Italy', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇮🇹' },
    { country_code: 'NL', country_name: 'Netherlands', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇳🇱' },
    { country_code: 'BE', country_name: 'Belgium', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇧🇪' },
    { country_code: 'PT', country_name: 'Portugal', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇵🇹' },
    { country_code: 'AT', country_name: 'Austria', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇦🇹' },
    { country_code: 'IE', country_name: 'Ireland', default_currency: 'EUR', currency_symbol: '€', primary_rail: 'SEPA_INSTANT', secondary_rail: 'SEPA', flag_emoji: '🇮🇪' },
    { country_code: 'SE', country_name: 'Sweden', default_currency: 'SEK', currency_symbol: 'kr', primary_rail: 'SEPA', flag_emoji: '🇸🇪' },
    { country_code: 'NO', country_name: 'Norway', default_currency: 'NOK', currency_symbol: 'kr', primary_rail: 'SEPA', flag_emoji: '🇳🇴' },
    { country_code: 'DK', country_name: 'Denmark', default_currency: 'DKK', currency_symbol: 'kr', primary_rail: 'SEPA', flag_emoji: '🇩🇰' },
    { country_code: 'CH', country_name: 'Switzerland', default_currency: 'CHF', currency_symbol: 'Fr', primary_rail: 'SEPA', flag_emoji: '🇨🇭' },
    { country_code: 'PL', country_name: 'Poland', default_currency: 'PLN', currency_symbol: 'zł', primary_rail: 'SEPA', flag_emoji: '🇵🇱' },
    { country_code: 'CA', country_name: 'Canada', default_currency: 'CAD', currency_symbol: 'C$', primary_rail: 'ETRANSFER', flag_emoji: '🇨🇦' },
    { country_code: 'AU', country_name: 'Australia', default_currency: 'AUD', currency_symbol: 'A$', primary_rail: 'NPP', flag_emoji: '🇦🇺' },
    { country_code: 'NZ', country_name: 'New Zealand', default_currency: 'NZD', currency_symbol: 'NZ$', primary_rail: 'SWIFT', flag_emoji: '🇳🇿' },
    { country_code: 'JP', country_name: 'Japan', default_currency: 'JPY', currency_symbol: '¥', primary_rail: 'SWIFT', flag_emoji: '🇯🇵' },
    { country_code: 'CN', country_name: 'China', default_currency: 'CNY', currency_symbol: '¥', primary_rail: 'SWIFT', flag_emoji: '🇨🇳', kyc_required: true },
    { country_code: 'IN', country_name: 'India', default_currency: 'INR', currency_symbol: '₹', primary_rail: 'IMPS', secondary_rail: 'NEFT', flag_emoji: '🇮🇳' },
    { country_code: 'SG', country_name: 'Singapore', default_currency: 'SGD', currency_symbol: 'S$', primary_rail: 'SWIFT', flag_emoji: '🇸🇬' },
    { country_code: 'HK', country_name: 'Hong Kong', default_currency: 'HKD', currency_symbol: 'HK$', primary_rail: 'SWIFT', flag_emoji: '🇭🇰' },
    { country_code: 'AE', country_name: 'United Arab Emirates', default_currency: 'AED', currency_symbol: 'AED', primary_rail: 'SWIFT', flag_emoji: '🇦🇪' },
    { country_code: 'SA', country_name: 'Saudi Arabia', default_currency: 'SAR', currency_symbol: 'SAR', primary_rail: 'SWIFT', flag_emoji: '🇸🇦' },
    { country_code: 'NG', country_name: 'Nigeria', default_currency: 'NGN', currency_symbol: '₦', primary_rail: 'NGIP', flag_emoji: '🇳🇬' },
    { country_code: 'GH', country_name: 'Ghana', default_currency: 'GHS', currency_symbol: '₵', primary_rail: 'SWIFT', flag_emoji: '🇬🇭' },
    { country_code: 'KE', country_name: 'Kenya', default_currency: 'KES', currency_symbol: 'KSh', primary_rail: 'SWIFT', flag_emoji: '🇰🇪' },
    { country_code: 'ZA', country_name: 'South Africa', default_currency: 'ZAR', currency_symbol: 'R', primary_rail: 'SWIFT', flag_emoji: '🇿🇦' },
    { country_code: 'MX', country_name: 'Mexico', default_currency: 'MXN', currency_symbol: 'MX$', primary_rail: 'SWIFT', flag_emoji: '🇲🇽' },
    { country_code: 'BR', country_name: 'Brazil', default_currency: 'BRL', currency_symbol: 'R$', primary_rail: 'SWIFT', flag_emoji: '🇧🇷' },
    { country_code: 'AR', country_name: 'Argentina', default_currency: 'ARS', currency_symbol: '$', primary_rail: 'SWIFT', flag_emoji: '🇦🇷' },
  ];
  await knex('country_wallet_map').insert(countries);
};

exports.down = async function (knex) {
  await knex.schema.dropTableIfExists('banking_transactions');
  await knex.schema.dropTableIfExists('banking_rails');
  await knex.schema.dropTableIfExists('zelle_transfers');
  await knex.schema.dropTableIfExists('country_wallet_map');
};
