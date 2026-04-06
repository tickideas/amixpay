exports.up = async (knex) => {
  await knex.schema.createTable('payment_requests', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('requester_id').notNullable().references('id').inTable('users');
    t.uuid('payer_id').notNullable().references('id').inTable('users');
    t.uuid('payment_id').references('id').inTable('payments');
    t.decimal('amount', 20, 8).notNullable();
    t.string('currency_code', 3).notNullable();
    t.text('note');
    t.enu('status', ['pending', 'accepted', 'declined', 'cancelled', 'expired']).defaultTo('pending');
    t.timestamp('expires_at');
    t.timestamps(true, true);
  });

  await knex.schema.createTable('splits', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('creator_id').notNullable().references('id').inTable('users');
    t.string('title').notNullable();
    t.decimal('total_amount', 20, 8).notNullable();
    t.string('currency_code', 3).notNullable();
    t.enu('status', ['open', 'completed', 'cancelled']).defaultTo('open');
    t.jsonb('items').defaultTo('[]');
    t.decimal('tax_amount', 20, 8).defaultTo(0);
    t.decimal('discount_amount', 20, 8).defaultTo(0);
    t.timestamps(true, true);
  });

  await knex.schema.createTable('split_shares', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('split_id').notNullable().references('id').inTable('splits').onDelete('CASCADE');
    t.uuid('user_id').notNullable().references('id').inTable('users');
    t.uuid('payment_id').references('id').inTable('payments');
    t.decimal('amount', 20, 8).notNullable();
    t.enu('status', ['pending', 'paid', 'declined']).defaultTo('pending');
    t.timestamps(true, true);
    t.unique(['split_id', 'user_id']);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('split_shares');
  await knex.schema.dropTableIfExists('splits');
  await knex.schema.dropTableIfExists('payment_requests');
};
