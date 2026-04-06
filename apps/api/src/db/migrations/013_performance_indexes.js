/**
 * Migration 013 — Performance indexes
 *
 * Adds indexes on all foreign keys and common query patterns.
 * Without these, every JOIN / WHERE on a FK does a sequential scan.
 *
 * Postgres auto-creates indexes for PRIMARY KEY and UNIQUE constraints,
 * but NOT for plain REFERENCES / foreign key columns.
 */

exports.up = async (knex) => {
  // ── transactions ───────────────────────────────────────────────────────────
  // Most-queried table: filtered by wallet_id, status, type, and sorted by created_at
  await knex.schema.alterTable('transactions', (t) => {
    t.index('wallet_id', 'idx_transactions_wallet_id');
    t.index('status', 'idx_transactions_status');
    t.index('type', 'idx_transactions_type');
    t.index('counterparty_user_id', 'idx_transactions_counterparty');
    t.index('created_at', 'idx_transactions_created_at');
    t.index('currency_code', 'idx_transactions_currency');
  });

  // ── ledger_entries ─────────────────────────────────────────────────────────
  // Audit trail: always queried by transaction_id or wallet_currency_id
  await knex.schema.alterTable('ledger_entries', (t) => {
    t.index('transaction_id', 'idx_ledger_transaction_id');
    t.index('wallet_currency_id', 'idx_ledger_wallet_currency_id');
    t.index('created_at', 'idx_ledger_created_at');
  });

  // ── payments ───────────────────────────────────────────────────────────────
  // Queried by sender, recipient, status
  await knex.schema.alterTable('payments', (t) => {
    t.index('sender_id', 'idx_payments_sender_id');
    t.index('recipient_id', 'idx_payments_recipient_id');
    t.index('status', 'idx_payments_status');
    t.index('created_at', 'idx_payments_created_at');
  });

  // ── international_transfers ────────────────────────────────────────────────
  await knex.schema.alterTable('international_transfers', (t) => {
    t.index('user_id', 'idx_intl_transfers_user_id');
    t.index('status', 'idx_intl_transfers_status');
    t.index('created_at', 'idx_intl_transfers_created_at');
  });

  // ── payment_requests ───────────────────────────────────────────────────────
  await knex.schema.alterTable('payment_requests', (t) => {
    t.index('requester_id', 'idx_payment_requests_requester');
    t.index('payer_id', 'idx_payment_requests_payer');
    t.index('status', 'idx_payment_requests_status');
  });

  // ── splits / split_shares ──────────────────────────────────────────────────
  await knex.schema.alterTable('splits', (t) => {
    t.index('creator_id', 'idx_splits_creator_id');
  });
  await knex.schema.alterTable('split_shares', (t) => {
    t.index('user_id', 'idx_split_shares_user_id');
    t.index('status', 'idx_split_shares_status');
  });

  // ── notifications ──────────────────────────────────────────────────────────
  // User's notification feed: by user_id, sorted by created_at, filtered by read
  await knex.schema.alterTable('notifications', (t) => {
    t.index('user_id', 'idx_notifications_user_id');
    t.index('created_at', 'idx_notifications_created_at');
    t.index('read', 'idx_notifications_read');
  });

  // ── fraud_alerts ───────────────────────────────────────────────────────────
  // Admin dashboard: by status, severity, created_at
  await knex.schema.alterTable('fraud_alerts', (t) => {
    t.index('user_id', 'idx_fraud_alerts_user_id');
    t.index('transaction_id', 'idx_fraud_alerts_transaction_id');
    t.index('status', 'idx_fraud_alerts_status');
    t.index('severity', 'idx_fraud_alerts_severity');
    t.index('created_at', 'idx_fraud_alerts_created_at');
  });

  // ── virtual_cards ──────────────────────────────────────────────────────────
  await knex.schema.alterTable('virtual_cards', (t) => {
    t.index('user_id', 'idx_virtual_cards_user_id');
    t.index('status', 'idx_virtual_cards_status');
  });

  // ── merchant_payments ──────────────────────────────────────────────────────
  await knex.schema.alterTable('merchant_payments', (t) => {
    t.index('merchant_id', 'idx_merchant_payments_merchant_id');
    t.index('payer_id', 'idx_merchant_payments_payer_id');
    t.index('status', 'idx_merchant_payments_status');
    t.index('created_at', 'idx_merchant_payments_created_at');
  });

  // ── checkout_links ─────────────────────────────────────────────────────────
  await knex.schema.alterTable('checkout_links', (t) => {
    t.index('merchant_id', 'idx_checkout_links_merchant_id');
  });

  // ── zelle_transfers ────────────────────────────────────────────────────────
  await knex.schema.alterTable('zelle_transfers', (t) => {
    t.index('sender_id', 'idx_zelle_sender_id');
    t.index('recipient_id', 'idx_zelle_recipient_id');
    t.index('status', 'idx_zelle_status');
    t.index('created_at', 'idx_zelle_created_at');
  });

  // ── banking_transactions ───────────────────────────────────────────────────
  await knex.schema.alterTable('banking_transactions', (t) => {
    t.index('user_id', 'idx_banking_tx_user_id');
    t.index('wallet_id', 'idx_banking_tx_wallet_id');
    t.index('status', 'idx_banking_tx_status');
    t.index('direction', 'idx_banking_tx_direction');
    t.index('created_at', 'idx_banking_tx_created_at');
  });

  // ── user_devices ───────────────────────────────────────────────────────────
  await knex.schema.alterTable('user_devices', (t) => {
    t.index('user_id', 'idx_user_devices_user_id');
  });

  // ── kyc_documents ──────────────────────────────────────────────────────────
  await knex.schema.alterTable('kyc_documents', (t) => {
    t.index('user_id', 'idx_kyc_documents_user_id');
    t.index('status', 'idx_kyc_documents_status');
  });
};

exports.down = async (knex) => {
  // Drop all indexes in reverse order
  const drops = [
    ['kyc_documents', ['idx_kyc_documents_user_id', 'idx_kyc_documents_status']],
    ['user_devices', ['idx_user_devices_user_id']],
    ['banking_transactions', ['idx_banking_tx_user_id', 'idx_banking_tx_wallet_id', 'idx_banking_tx_status', 'idx_banking_tx_direction', 'idx_banking_tx_created_at']],
    ['zelle_transfers', ['idx_zelle_sender_id', 'idx_zelle_recipient_id', 'idx_zelle_status', 'idx_zelle_created_at']],
    ['checkout_links', ['idx_checkout_links_merchant_id']],
    ['merchant_payments', ['idx_merchant_payments_merchant_id', 'idx_merchant_payments_payer_id', 'idx_merchant_payments_status', 'idx_merchant_payments_created_at']],
    ['virtual_cards', ['idx_virtual_cards_user_id', 'idx_virtual_cards_status']],
    ['fraud_alerts', ['idx_fraud_alerts_user_id', 'idx_fraud_alerts_transaction_id', 'idx_fraud_alerts_status', 'idx_fraud_alerts_severity', 'idx_fraud_alerts_created_at']],
    ['notifications', ['idx_notifications_user_id', 'idx_notifications_created_at', 'idx_notifications_read']],
    ['split_shares', ['idx_split_shares_user_id', 'idx_split_shares_status']],
    ['splits', ['idx_splits_creator_id']],
    ['payment_requests', ['idx_payment_requests_requester', 'idx_payment_requests_payer', 'idx_payment_requests_status']],
    ['international_transfers', ['idx_intl_transfers_user_id', 'idx_intl_transfers_status', 'idx_intl_transfers_created_at']],
    ['payments', ['idx_payments_sender_id', 'idx_payments_recipient_id', 'idx_payments_status', 'idx_payments_created_at']],
    ['ledger_entries', ['idx_ledger_transaction_id', 'idx_ledger_wallet_currency_id', 'idx_ledger_created_at']],
    ['transactions', ['idx_transactions_wallet_id', 'idx_transactions_status', 'idx_transactions_type', 'idx_transactions_counterparty', 'idx_transactions_created_at', 'idx_transactions_currency']],
  ];

  for (const [table, indexes] of drops) {
    await knex.schema.alterTable(table, (t) => {
      indexes.forEach((idx) => t.dropIndex([], idx));
    });
  }
};
