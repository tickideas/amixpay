exports.up = async (knex) => {
  await knex.schema.createTable('notifications', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.enu('type', [
      'payment_received', 'payment_sent', 'payment_request',
      'transfer_update', 'card_transaction', 'security_alert',
      'kyc_update', 'promotional', 'system',
    ]).notNullable();
    t.string('title').notNullable();
    t.text('body').notNullable();
    t.jsonb('data').defaultTo('{}');
    t.boolean('read').defaultTo(false);
    t.timestamp('read_at');
    t.timestamp('created_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('notification_preferences', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().unique().references('id').inTable('users').onDelete('CASCADE');
    t.boolean('push_enabled').defaultTo(true);
    t.boolean('sms_enabled').defaultTo(true);
    t.boolean('email_enabled').defaultTo(true);
    t.boolean('payment_alerts').defaultTo(true);
    t.boolean('security_alerts').defaultTo(true);
    t.boolean('promotional').defaultTo(false);
    t.timestamps(true, true);
  });

  await knex.schema.createTable('fraud_alerts', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').references('id').inTable('users');
    t.uuid('transaction_id').references('id').inTable('transactions');
    t.enu('severity', ['low', 'medium', 'high', 'critical']).notNullable();
    t.string('rule_triggered').notNullable();
    t.text('description');
    t.integer('risk_score').notNullable();
    t.enu('status', ['open', 'reviewed', 'blocked', 'dismissed']).defaultTo('open');
    t.uuid('reviewed_by').references('id').inTable('users');
    t.text('review_notes');
    t.timestamp('reviewed_at');
    t.jsonb('metadata').defaultTo('{}');
    t.timestamp('created_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('exchange_rates_cache', (t) => {
    t.string('base_currency', 3).primary();
    t.jsonb('rates').notNullable();
    t.timestamp('fetched_at').defaultTo(knex.fn.now());
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('exchange_rates_cache');
  await knex.schema.dropTableIfExists('fraud_alerts');
  await knex.schema.dropTableIfExists('notification_preferences');
  await knex.schema.dropTableIfExists('notifications');
};
