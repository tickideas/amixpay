require('dotenv').config();

// DATABASE_URL takes precedence (Railway, Heroku, etc.).
// Fall back to individual DB_* vars for Docker/Dokploy.
// Set DB_SSL=true if connecting to an external managed DB that requires SSL.
const useSSL = process.env.DB_SSL === 'true';
const sslConfig = useSSL ? { ssl: { rejectUnauthorized: false } } : {};
const prodConnection = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL, ...sslConfig }
  : {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'amixpay',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
      ...sslConfig,
    };

const devConnection = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'amixpay',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
};

module.exports = {
  development: {
    client: 'pg',
    connection: devConnection,
    pool: { min: 2, max: 10 },
    migrations: { directory: './src/db/migrations', tableName: 'knex_migrations' },
    seeds: { directory: './src/db/seeds' },
  },
  test: {
    client: 'pg',
    connection: {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      database: process.env.DB_NAME || 'amixpay_test',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    },
    pool: { min: 1, max: 5 },
    migrations: { directory: './src/db/migrations', tableName: 'knex_migrations' },
  },
  production: {
    client: 'pg',
    connection: prodConnection,
    pool: { min: 2, max: 20 },
    migrations: { directory: './src/db/migrations', tableName: 'knex_migrations' },
  },
};
