exports.up = async (knex) => {
  await knex.schema.createTable('payments', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('sender_id').notNullable().references('id').inTable('users');
    t.uuid('recipient_id').notNullable().references('id').inTable('users');
    t.uuid('sender_transaction_id').references('id').inTable('transactions');
    t.uuid('recipient_transaction_id').references('id').inTable('transactions');
    t.decimal('amount', 20, 8).notNullable();
    t.string('currency_code', 3).notNullable();
    t.decimal('fee_amount', 20, 8).defaultTo(0);
    t.enu('status', ['pending', 'completed', 'failed', 'cancelled']).defaultTo('pending');
    t.string('reference_id', 100).unique();
    t.text('note');
    t.boolean('is_anonymous').defaultTo(false);
    t.jsonb('fraud_flags').defaultTo('[]');
    t.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('payments');
};
