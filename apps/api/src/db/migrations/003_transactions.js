exports.up = async (knex) => {
  await knex.schema.createTable('transactions', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('wallet_id').notNullable().references('id').inTable('wallets').onDelete('CASCADE');
    t.enu('type', [
      'send', 'receive', 'request', 'qr_payment',
      'international_transfer', 'fund', 'withdraw',
      'card_payment', 'split', 'merchant_payment', 'refund',
    ]).notNullable();
    t.enu('status', [
      'pending', 'processing', 'completed', 'failed', 'cancelled', 'expired',
    ]).defaultTo('pending');
    t.decimal('amount', 20, 8).notNullable();
    t.string('currency_code', 3).notNullable();
    t.decimal('fee_amount', 20, 8).defaultTo(0);
    t.string('fee_currency', 3);
    t.decimal('exchange_rate', 20, 8);
    t.string('reference_id', 100).unique();
    t.text('description');
    t.jsonb('metadata').defaultTo('{}');
    t.uuid('counterparty_user_id').references('id').inTable('users');
    t.string('counterparty_name');
    t.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('transactions');
};
