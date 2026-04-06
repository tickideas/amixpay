exports.up = async (knex) => {
  await knex.schema.alterTable('wallet_currencies', (t) => {
    // Persisted portfolio color index (0–7) so colors are stable across re-orders
    t.integer('color_index').defaultTo(null);
  });
};

exports.down = async (knex) => {
  await knex.schema.alterTable('wallet_currencies', (t) => {
    t.dropColumn('color_index');
  });
};
