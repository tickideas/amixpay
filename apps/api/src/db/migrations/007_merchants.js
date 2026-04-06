exports.up = async (knex) => {
  await knex.schema.createTable('merchants', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().unique().references('id').inTable('users').onDelete('CASCADE');
    t.string('business_name').notNullable();
    t.string('business_type');
    t.string('website_url');
    t.string('support_email');
    t.string('stripe_account_id');
    t.enu('status', ['pending', 'active', 'suspended']).defaultTo('pending');
    t.decimal('total_volume', 20, 8).defaultTo(0);
    t.decimal('pending_settlement', 20, 8).defaultTo(0);
    t.timestamps(true, true);
  });

  await knex.schema.createTable('merchant_payments', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('merchant_id').notNullable().references('id').inTable('merchants').onDelete('CASCADE');
    t.uuid('payer_id').references('id').inTable('users');
    t.uuid('transaction_id').references('id').inTable('transactions');
    t.decimal('amount', 20, 8).notNullable();
    t.string('currency_code', 3).notNullable();
    t.string('reference_id', 100).unique();
    t.string('description');
    t.enu('status', ['pending', 'completed', 'refunded', 'failed']).defaultTo('pending');
    t.string('checkout_link_id');
    t.jsonb('metadata').defaultTo('{}');
    t.timestamps(true, true);
  });

  await knex.schema.createTable('checkout_links', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('merchant_id').notNullable().references('id').inTable('merchants').onDelete('CASCADE');
    t.string('slug', 50).unique().notNullable();
    t.decimal('amount', 20, 8);
    t.boolean('fixed_amount').defaultTo(false);
    t.string('currency_code', 3).defaultTo('USD');
    t.string('title');
    t.text('description');
    t.boolean('active').defaultTo(true);
    t.timestamp('expires_at');
    t.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('checkout_links');
  await knex.schema.dropTableIfExists('merchant_payments');
  await knex.schema.dropTableIfExists('merchants');
};
