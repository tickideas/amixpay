require('dotenv').config();

// Railway injects DATABASE_URL automatically. Fall back to individual DB_* vars for local/Docker.
const prodConnection = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } }
  : {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      ssl: { rejectUnauthorized: false },
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
