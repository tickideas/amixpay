exports.up = async (knex) => {
  await knex.schema.createTable('ledger_entries', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('transaction_id').notNullable().references('id').inTable('transactions').onDelete('CASCADE');
    t.uuid('wallet_currency_id').notNullable().references('id').inTable('wallet_currencies').onDelete('CASCADE');
    t.enu('entry_type', ['debit', 'credit']).notNullable();
    t.decimal('amount', 20, 8).notNullable();
    t.decimal('balance_after', 20, 8).notNullable();
    t.timestamp('created_at').defaultTo(knex.fn.now());
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('ledger_entries');
};
