const request = require('supertest');
const { app, db, setupDatabase, teardownDatabase, createTestUser } = require('./setup');

beforeAll(async () => { await setupDatabase(); });
afterAll(async () => { await teardownDatabase(); });

describe('Input Validation — Amount Limits', () => {
  let token;

  beforeAll(async () => {
    const { accessToken } = await createTestUser(request);
    token = accessToken;
  });

  test('rejects NaN amount', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${token}`)
      .send({ recipient: 'anyone@test.com', amount: 'not_a_number', currencyCode: 'USD' })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('rejects Infinity amount', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${token}`)
      .send({ recipient: 'anyone@test.com', amount: 'Infinity', currencyCode: 'USD' })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('rejects negative amount', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${token}`)
      .send({ recipient: 'anyone@test.com', amount: -100, currencyCode: 'USD' })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('rejects dust amount (below 0.01)', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${token}`)
      .send({ recipient: 'anyone@test.com', amount: 0.001, currencyCode: 'USD' })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('rejects amount exceeding KYC limit (unverified user)', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${token}`)
      .send({ recipient: 'anyone@test.com', amount: 600, currencyCode: 'USD' })
      .expect(400);

    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('per-transaction limit');
  });

  test('rejects amount exceeding absolute max (1M)', async () => {
    const res = await request(app)
      .post('/v1/transfers/international/quote')
      .set('Authorization', `Bearer ${token}`)
      .send({ sourceCurrency: 'USD', targetCurrency: 'EUR', sourceAmount: 2000000 })
      .expect(400);

    expect(res.body.success).toBe(false);
  });
});

describe('Input Validation — Auth Fields', () => {
  test('rejects invalid email format', async () => {
    const res = await request(app)
      .post('/v1/auth/register')
      .send({
        email: 'not-an-email',
        password: 'ValidPass123!',
        firstName: 'Test',
        lastName: 'User',
        username: 'validuser',
      })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('rejects username with special characters', async () => {
    const res = await request(app)
      .post('/v1/auth/register')
      .send({
        email: 'special@amixpay.test',
        password: 'ValidPass123!',
        firstName: 'Test',
        lastName: 'User',
        username: 'user@name!',
      })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('rejects short username', async () => {
    const res = await request(app)
      .post('/v1/auth/register')
      .send({
        email: 'short@amixpay.test',
        password: 'ValidPass123!',
        firstName: 'Test',
        lastName: 'User',
        username: 'ab',
      })
      .expect(400);

    expect(res.body.success).toBe(false);
  });
});
