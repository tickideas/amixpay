exports.up = async (knex) => {
  await knex.schema.createTable('users', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.string('username', 50).unique().notNullable();
    t.string('email', 255).unique().notNullable();
    t.string('phone', 30).unique();
    t.string('password_hash').notNullable();
    t.string('first_name', 100).notNullable();
    t.string('last_name', 100).notNullable();
    t.date('date_of_birth');
    t.string('country_code', 3);
    t.string('avatar_url');
    t.enu('kyc_status', ['none', 'pending', 'under_review', 'approved', 'rejected']).defaultTo('none');
    t.integer('kyc_level').defaultTo(0);
    t.enu('status', ['active', 'suspended', 'closed']).defaultTo('active');
    t.boolean('two_factor_on').defaultTo(false);
    t.boolean('email_verified').defaultTo(false);
    t.boolean('phone_verified').defaultTo(false);
    t.enu('role', ['user', 'merchant', 'admin']).defaultTo('user');
    t.timestamp('last_login_at');
    t.timestamps(true, true);
  });

  await knex.schema.createTable('user_devices', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.string('device_token').notNullable();
    t.enu('platform', ['ios', 'android', 'web']).notNullable();
    t.string('device_name');
    t.timestamp('last_active_at');
    t.timestamps(true, true);
    t.unique(['user_id', 'device_token']);
  });

  await knex.schema.createTable('two_factor_auth', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().unique().references('id').inTable('users').onDelete('CASCADE');
    t.enu('method', ['totp', 'sms']).defaultTo('totp');
    t.text('secret_encrypted');
    t.text('backup_codes_enc');
    t.timestamp('enabled_at');
    t.timestamps(true, true);
  });

  await knex.schema.createTable('kyc_documents', (t) => {
    t.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.enu('type', ['national_id', 'passport', 'drivers_license', 'utility_bill', 'selfie']).notNullable();
    t.string('s3_key').notNullable();
    t.enu('status', ['pending', 'approved', 'rejected']).defaultTo('pending');
    t.text('rejection_reason');
    t.timestamps(true, true);
  });
};

exports.down = async (knex) => {
  await knex.schema.dropTableIfExists('kyc_documents');
  await knex.schema.dropTableIfExists('two_factor_auth');
  await knex.schema.dropTableIfExists('user_devices');
  await knex.schema.dropTableIfExists('users');
};
