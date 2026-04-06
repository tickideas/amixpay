exports.up = async (knex) => {
  await knex.schema.createTable('virtual_cards', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.string('stripe_card_id').unique();
    t.string('last_four', 4).notNullable();
    t.string('card_holder_name').notNullable();
    t.string('brand').defaultTo('visa');
    t.integer('exp_month').notNullable();
    t.integer('exp_year').notNullable();
    t.string('currency_code', 3).defaultTo('USD');
    t.decimal('spending_limit', 20, 8);
    t.enu('spending_interval', ['daily', 'weekly', 'monthly', 'total']);
    t.decimal('amount_spent', 20, 8).defaultTo(0);
    t.enu('status', ['active', 'frozen', 'cancelled']).defaultTo('active');
    t.jsonb('allowed_categories').defaultTo('[]');
    t.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('virtual_cards');
};
