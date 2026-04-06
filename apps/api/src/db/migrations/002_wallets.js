exports.up = async (knex) => {
  await knex.schema.createTable('wallets', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().unique().references('id').inTable('users').onDelete('CASCADE');
    t.string('primary_currency', 3).defaultTo('USD');
    t.enu('status', ['active', 'frozen', 'closed']).defaultTo('active');
    t.string('stripe_customer_id');
    t.string('plaid_access_token');
    t.timestamps(true, true);
  });

  await knex.schema.createTable('wallet_currencies', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('wallet_id').notNullable().references('id').inTable('wallets').onDelete('CASCADE');
    t.string('currency_code', 3).notNullable();
    t.decimal('balance', 20, 8).defaultTo(0);
    t.decimal('available_balance', 20, 8).defaultTo(0);
    t.decimal('pending_balance', 20, 8).defaultTo(0);
    t.timestamps(true, true);
    t.unique(['wallet_id', 'currency_code']);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('wallet_currencies');
  await knex.schema.dropTableIfExists('wallets');
};
