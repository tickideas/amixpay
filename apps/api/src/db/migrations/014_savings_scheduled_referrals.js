/**
 * Migration 014 — Savings Goals, Scheduled Transfers, Referrals
 *
 * Three new feature tables that currently have Flutter UI but no backend.
 */

exports.up = async (knex) => {
  // ── Savings Goals ──────────────────────────────────────────────────────────
  await knex.schema.createTable('savings_goals', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.string('name', 100).notNullable();
    t.string('emoji', 10).defaultTo('🎯');
    t.decimal('target_amount', 20, 8).notNullable();
    t.decimal('saved_amount', 20, 8).defaultTo(0);
    t.string('currency_code', 3).notNullable().defaultTo('USD');
    t.date('target_date');
    t.integer('color_index').defaultTo(0);
    t.enu('status', ['active', 'completed', 'cancelled']).defaultTo('active');
    t.timestamps(true, true);

    t.index('user_id', 'idx_savings_goals_user_id');
    t.index('status', 'idx_savings_goals_status');
  });

  // ── Scheduled Transfers ────────────────────────────────────────────────────
  await knex.schema.createTable('scheduled_transfers', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.string('recipient_identifier').notNullable(); // email/phone/username
    t.string('recipient_name');
    t.decimal('amount', 20, 8).notNullable();
    t.string('currency_code', 3).notNullable().defaultTo('USD');
    t.text('description');
    t.enu('frequency', ['once', 'daily', 'weekly', 'biweekly', 'monthly']).notNullable();
    t.date('next_run_date').notNullable();
    t.date('end_date');  // null = runs indefinitely (or until cancelled)
    t.integer('total_runs').defaultTo(0);
    t.integer('completed_runs').defaultTo(0);
    t.uuid('last_payment_id').references('id').inTable('payments');
    t.enu('status', ['active', 'paused', 'completed', 'cancelled', 'failed']).defaultTo('active');
    t.text('last_error');
    t.timestamps(true, true);

    t.index('user_id', 'idx_scheduled_transfers_user_id');
    t.index('status', 'idx_scheduled_transfers_status');
    t.index('next_run_date', 'idx_scheduled_transfers_next_run');
  });

  // ── Referrals ──────────────────────────────────────────────────────────────
  await knex.schema.createTable('referral_codes', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().unique().references('id').inTable('users').onDelete('CASCADE');
    t.string('code', 20).notNullable().unique(); // e.g. AMIX-A1B2C3
    t.integer('total_referrals').defaultTo(0);
    t.decimal('total_earned', 20, 8).defaultTo(0);
    t.string('reward_currency', 3).defaultTo('USD');
    t.timestamps(true, true);
  });

  await knex.schema.createTable('referrals', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('referrer_id').notNullable().references('id').inTable('users');
    t.uuid('referred_id').notNullable().unique().references('id').inTable('users');
    t.string('code_used', 20).notNullable();
    t.enu('status', ['pending', 'qualified', 'rewarded', 'expired']).defaultTo('pending');
    t.decimal('reward_amount', 20, 8).defaultTo(0);
    t.string('reward_currency', 3).defaultTo('USD');
    t.timestamp('qualified_at');  // when referred user met the reward criteria
    t.timestamp('rewarded_at');   // when reward was credited
    t.timestamps(true, true);

    t.index('referrer_id', 'idx_referrals_referrer_id');
    t.index('status', 'idx_referrals_status');
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('referrals');
  await knex.schema.dropTableIfExists('referral_codes');
  await knex.schema.dropTableIfExists('scheduled_transfers');
  await knex.schema.dropTableIfExists('savings_goals');
};
