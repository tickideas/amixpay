const request = require('supertest');
const { app, db, setupDatabase, teardownDatabase, createTestUser } = require('./setup');

beforeAll(async () => { await setupDatabase(); });
afterAll(async () => { await teardownDatabase(); });

describe('Security — Authentication', () => {
  test('rejects requests without Authorization header', async () => {
    const res = await request(app)
      .get('/v1/users/me')
      .expect(401);

    expect(res.body.success).toBe(false);
  });

  test('rejects malformed Authorization header', async () => {
    const res = await request(app)
      .get('/v1/users/me')
      .set('Authorization', 'InvalidFormat token123')
      .expect(401);

    expect(res.body.success).toBe(false);
  });

  test('rejects expired/invalid JWT', async () => {
    const res = await request(app)
      .get('/v1/users/me')
      .set('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.invalid')
      .expect(401);

    expect(res.body.success).toBe(false);
  });

  test('protected routes require auth', async () => {
    const protectedRoutes = [
      { method: 'get', path: '/v1/wallets' },
      { method: 'get', path: '/v1/wallets/transactions' },
      { method: 'post', path: '/v1/payments/send' },
      { method: 'get', path: '/v1/notifications' },
    ];

    for (const route of protectedRoutes) {
      const res = await request(app)[route.method](route.path).expect(401);
      expect(res.body.success).toBe(false);
    }
  });
});

describe('Security — User Data', () => {
  test('register response never includes password hash', async () => {
    const res = await request(app)
      .post('/v1/auth/register')
      .send({
        email: `security_test_${Date.now()}@amixpay.test`,
        password: 'SecurePass123!',
        firstName: 'Secure',
        lastName: 'User',
        username: `secureuser_${Date.now()}`,
      })
      .expect(201);

    const json = JSON.stringify(res.body);
    expect(json).not.toContain('password_hash');
    expect(json).not.toContain('SecurePass123');
  });

  test('login response never includes password hash', async () => {
    const { credentials } = await createTestUser(request);
    const res = await request(app)
      .post('/v1/auth/login')
      .send({ email: credentials.email, password: credentials.password })
      .expect(200);

    const json = JSON.stringify(res.body);
    expect(json).not.toContain('password_hash');
  });
});

describe('Security — Health Check', () => {
  test('GET /health — accessible without auth', async () => {
    const res = await request(app)
      .get('/health')
      .expect(200);

    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('amixpay-api');
  });
});

describe('Security — 404 Handler', () => {
  test('returns proper 404 for unknown routes', async () => {
    const res = await request(app)
      .get('/v1/nonexistent')
      .expect(404);

    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});

describe('Security — Helmet Headers', () => {
  test('sets security headers', async () => {
    const res = await request(app).get('/health');

    // Helmet should set these
    expect(res.headers['x-content-type-options']).toBe('nosniff');
    expect(res.headers['x-frame-options']).toBeDefined();
  });
});
