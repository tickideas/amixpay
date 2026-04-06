exports.up = async (knex) => {
  await knex.schema.createTable('international_transfers', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users');
    t.uuid('transaction_id').references('id').inTable('transactions');
    t.decimal('source_amount', 20, 8).notNullable();
    t.string('source_currency', 3).notNullable();
    t.decimal('target_amount', 20, 8).notNullable();
    t.string('target_currency', 3).notNullable();
    t.decimal('exchange_rate', 20, 8).notNullable();
    t.decimal('fee_amount', 20, 8).defaultTo(0);
    t.string('wise_quote_id');
    t.string('wise_transfer_id');
    t.string('wise_profile_id');
    t.enu('status', [
      'quote', 'pending', 'processing',
      'funds_converted', 'outgoing_payment_sent', 'completed', 'cancelled', 'failed',
    ]).defaultTo('quote');
    t.string('recipient_account_number');
    t.string('recipient_routing_number');
    t.string('recipient_iban');
    t.string('recipient_bic');
    t.string('recipient_bank_name');
    t.string('recipient_name');
    t.string('recipient_country', 3);
    t.text('purpose');
    t.timestamp('estimated_delivery');
    t.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('international_transfers');
};
