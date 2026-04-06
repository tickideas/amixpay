const db = require('../knex');

const TABLE = 'users';

const SAFE_FIELDS = [
  'id', 'username', 'email', 'phone', 'first_name', 'last_name',
  'date_of_birth', 'country_code', 'avatar_url', 'kyc_status',
  'kyc_level', 'status', 'two_factor_on', 'email_verified',
  'phone_verified', 'role', 'last_login_at', 'created_at', 'updated_at',
];

const User = {
  findById: (id) => db(TABLE).where({ id }).first(),

  findByEmail: (email) => db(TABLE).where({ email: email.toLowerCase() }).first(),

  findByUsername: (username) => db(TABLE).where({ username }).first(),

  findByPhone: (phone) => db(TABLE).where({ phone }).first(),

  findByIdentifier: (identifier) =>
    db(TABLE)
      .where('email', identifier.toLowerCase())
      .orWhere('username', identifier)
      .orWhere('phone', identifier)
      .first(),

  create: (data) =>
    db(TABLE)
      .insert({ ...data, email: data.email.toLowerCase() })
      .returning('*')
      .then((rows) => rows[0]),

  update: (id, data) =>
    db(TABLE)
      .where({ id })
      .update({ ...data, updated_at: db.fn.now() })
      .returning('*')
      .then((rows) => rows[0]),

  safeFields: (user) => {
    if (!user) return null;
    return SAFE_FIELDS.reduce((acc, key) => {
      if (key in user) acc[key] = user[key];
      return acc;
    }, {});
  },

  list: ({ limit = 20, offset = 0, status } = {}) => {
    const q = db(TABLE).select(SAFE_FIELDS).limit(limit).offset(offset).orderBy('created_at', 'desc');
    if (status) q.where({ status });
    return q;
  },
};

module.exports = User;
