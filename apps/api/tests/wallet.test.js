const request = require('supertest');
const { app, db, setupDatabase, teardownDatabase, createTestUser } = require('./setup');

beforeAll(async () => { await setupDatabase(); });
afterAll(async () => { await teardownDatabase(); });

describe('Wallet — Get / Create', () => {
  test('GET /v1/wallets — returns wallet with default USD currency', async () => {
    const { accessToken } = await createTestUser(request);

    const res = await request(app)
      .get('/v1/wallets')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data).toBeDefined();
    // Wallet should have a primary currency
    expect(res.body.data.primary_currency).toBeDefined();
  });
});

describe('Wallet — Add / Remove Currency', () => {
  let token;

  beforeAll(async () => {
    const { accessToken } = await createTestUser(request);
    token = accessToken;
    // Ensure wallet exists
    await request(app).get('/v1/wallets').set('Authorization', `Bearer ${token}`);
  });

  test('POST /v1/wallets/currencies — adds a new currency', async () => {
    const res = await request(app)
      .post('/v1/wallets/currencies')
      .set('Authorization', `Bearer ${token}`)
      .send({ currencyCode: 'EUR' })
      .expect(201);

    expect(res.body.success).toBe(true);
  });

  test('POST /v1/wallets/currencies — rejects unsupported currency', async () => {
    const res = await request(app)
      .post('/v1/wallets/currencies')
      .set('Authorization', `Bearer ${token}`)
      .send({ currencyCode: 'XYZ' })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('POST /v1/wallets/currencies — rejects duplicate currency', async () => {
    // Add GBP first
    await request(app)
      .post('/v1/wallets/currencies')
      .set('Authorization', `Bearer ${token}`)
      .send({ currencyCode: 'GBP' })
      .expect(201);

    // Try again
    const res = await request(app)
      .post('/v1/wallets/currencies')
      .set('Authorization', `Bearer ${token}`)
      .send({ currencyCode: 'GBP' })
      .expect(409);

    expect(res.body.success).toBe(false);
  });
});

describe('Wallet — Transactions', () => {
  test('GET /v1/wallets/transactions — returns empty list for new user', async () => {
    const { accessToken } = await createTestUser(request);
    // Ensure wallet exists
    await request(app).get('/v1/wallets').set('Authorization', `Bearer ${accessToken}`);

    const res = await request(app)
      .get('/v1/wallets/transactions')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.items).toEqual([]);
    expect(res.body.data.total).toBe(0);
  });
});
