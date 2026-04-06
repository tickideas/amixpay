const request = require('supertest');
const { app, db, setupDatabase, teardownDatabase, createTestUser } = require('./setup');

beforeAll(async () => { await setupDatabase(); });
afterAll(async () => { await teardownDatabase(); });

describe('Auth — Registration', () => {
  test('POST /v1/auth/register — creates user and returns tokens', async () => {
    const res = await request(app)
      .post('/v1/auth/register')
      .send({
        email: 'newuser@amixpay.test',
        password: 'SecurePass123!',
        firstName: 'Jane',
        lastName: 'Doe',
        username: 'janedoe',
        countryCode: 'US',
      })
      .expect(201);

    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe('newuser@amixpay.test');
    expect(res.body.data.user.username).toBe('janedoe');
    expect(res.body.data.user.first_name).toBe('Jane');
    expect(res.body.data.access_token).toBeDefined();
    expect(res.body.data.refresh_token).toBeDefined();
    // Should NOT return password hash
    expect(res.body.data.user.password_hash).toBeUndefined();
  });

  test('POST /v1/auth/register — rejects duplicate email', async () => {
    // First registration
    await request(app)
      .post('/v1/auth/register')
      .send({
        email: 'dupe@amixpay.test',
        password: 'SecurePass123!',
        firstName: 'First',
        lastName: 'User',
        username: 'firstuser',
      })
      .expect(201);

    // Duplicate
    const res = await request(app)
      .post('/v1/auth/register')
      .send({
        email: 'dupe@amixpay.test',
        password: 'SecurePass123!',
        firstName: 'Second',
        lastName: 'User',
        username: 'seconduser',
      })
      .expect(409);

    expect(res.body.success).toBe(false);
  });

  test('POST /v1/auth/register — rejects weak password', async () => {
    const res = await request(app)
      .post('/v1/auth/register')
      .send({
        email: 'weak@amixpay.test',
        password: '123',
        firstName: 'Weak',
        lastName: 'Pass',
        username: 'weakpass',
      })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('POST /v1/auth/register — rejects missing fields', async () => {
    const res = await request(app)
      .post('/v1/auth/register')
      .send({ email: 'missing@amixpay.test' })
      .expect(400);

    expect(res.body.success).toBe(false);
  });
});

describe('Auth — Login', () => {
  let testCreds;

  beforeAll(async () => {
    const { credentials } = await createTestUser(request);
    testCreds = credentials;
  });

  test('POST /v1/auth/login — succeeds with correct credentials', async () => {
    const res = await request(app)
      .post('/v1/auth/login')
      .send({ email: testCreds.email, password: testCreds.password })
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.user).toBeDefined();
    expect(res.body.data.access_token).toBeDefined();
    expect(res.body.data.refresh_token).toBeDefined();
  });

  test('POST /v1/auth/login — fails with wrong password', async () => {
    const res = await request(app)
      .post('/v1/auth/login')
      .send({ email: testCreds.email, password: 'WrongPassword99!' })
      .expect(401);

    expect(res.body.success).toBe(false);
  });

  test('POST /v1/auth/login — fails with non-existent email', async () => {
    const res = await request(app)
      .post('/v1/auth/login')
      .send({ email: 'nobody@amixpay.test', password: 'SomePass123!' })
      .expect(401);

    expect(res.body.success).toBe(false);
  });
});

describe('Auth — Token Refresh', () => {
  test('POST /v1/auth/refresh — issues new tokens and rotates refresh token', async () => {
    const { refreshToken } = await createTestUser(request);

    const res = await request(app)
      .post('/v1/auth/refresh')
      .send({ refreshToken })
      .expect(200);

    expect(res.body.data.access_token).toBeDefined();
    expect(res.body.data.refresh_token).toBeDefined();
    // Old refresh token should no longer work
    expect(res.body.data.refresh_token).not.toBe(refreshToken);
  });

  test('POST /v1/auth/refresh — rejects invalid refresh token', async () => {
    const res = await request(app)
      .post('/v1/auth/refresh')
      .send({ refreshToken: 'invalid_token_abc123' })
      .expect(401);

    expect(res.body.success).toBe(false);
  });
});

describe('Auth — Logout', () => {
  test('POST /v1/auth/logout — blacklists access token', async () => {
    const { accessToken, refreshToken } = await createTestUser(request);

    // Logout
    await request(app)
      .post('/v1/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ refreshToken })
      .expect(200);

    // Token should now be rejected
    const res = await request(app)
      .get('/v1/users/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(401);

    expect(res.body.success).toBe(false);
  });
});

describe('Auth — Forgot / Reset Password', () => {
  test('POST /v1/auth/forgot-password — returns success regardless of email', async () => {
    // Existing email
    const { credentials } = await createTestUser(request);
    const res1 = await request(app)
      .post('/v1/auth/forgot-password')
      .send({ email: credentials.email })
      .expect(200);
    expect(res1.body.success).toBe(true);

    // Non-existing email — still returns success (prevent enumeration)
    const res2 = await request(app)
      .post('/v1/auth/forgot-password')
      .send({ email: 'nonexistent@amixpay.test' })
      .expect(200);
    expect(res2.body.success).toBe(true);
  });
});
