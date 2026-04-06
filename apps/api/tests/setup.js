/**
 * Test setup — provides a clean DB and app instance for integration tests.
 *
 * Each test file gets a fresh database (migrations rolled back + re-applied).
 * Redis is bypassed entirely — forces the in-memory fallback.
 */

// Force test environment BEFORE any requires
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_jwt_secret_for_ci_only_never_use_in_production';
// Use a non-routable address so Redis immediately fails and falls back to memory
process.env.REDIS_URL = 'redis://240.0.0.0:1';

const db = require('../src/db/knex');
const app = require('../src/app');

/** Run migrations to set up a clean schema */
async function setupDatabase() {
  await db.migrate.rollback(undefined, true); // rollback all
  await db.migrate.latest();
}

/** Tear down — destroy the DB connection pool */
async function teardownDatabase() {
  await db.destroy();
}

/** Create a test user and return tokens */
async function createTestUser(supertest, overrides = {}) {
  const ts = Date.now() + Math.random().toString(36).slice(2, 6);
  const userData = {
    email: `test_${ts}@amixpay.test`,
    password: 'TestPass123!',
    firstName: 'Test',
    lastName: 'User',
    username: `testuser_${ts}`,
    countryCode: 'US',
    ...overrides,
  };

  const res = await supertest(app)
    .post('/v1/auth/register')
    .send(userData)
    .expect(201);

  return {
    user: res.body.data.user,
    accessToken: res.body.data.access_token,
    refreshToken: res.body.data.refresh_token,
    credentials: userData,
  };
}

module.exports = { db, app, setupDatabase, teardownDatabase, createTestUser };
