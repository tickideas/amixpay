const request = require('supertest');
const { app, db, setupDatabase, teardownDatabase, createTestUser } = require('./setup');

beforeAll(async () => { await setupDatabase(); });
afterAll(async () => { await teardownDatabase(); });

describe('Payments — Send', () => {
  let sender, receiver;

  beforeAll(async () => {
    sender = await createTestUser(request, {
      email: 'sender@amixpay.test',
      username: 'sender01',
    });
    receiver = await createTestUser(request, {
      email: 'receiver@amixpay.test',
      username: 'receiver01',
    });

    // Fund the sender's wallet with $1000 for testing
    const senderWallet = await db('wallets').where({ user_id: sender.user.id }).first();
    if (senderWallet) {
      await db('wallet_currencies')
        .where({ wallet_id: senderWallet.id, currency_code: 'USD' })
        .update({ balance: 1000, available_balance: 1000 });
    }
  });

  test('POST /v1/payments/send — sends money to another user', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${sender.accessToken}`)
      .send({
        recipient: 'receiver@amixpay.test',
        amount: 50,
        currencyCode: 'USD',
        note: 'Test payment',
      })
      .expect(201);

    expect(res.body.success).toBe(true);
    expect(res.body.data.payment).toBeDefined();
    expect(res.body.data.payment.status).toBe('completed');
    expect(parseFloat(res.body.data.payment.amount)).toBe(50);
  });

  test('POST /v1/payments/send — rejects sending to self', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${sender.accessToken}`)
      .send({
        recipient: sender.credentials.email,
        amount: 10,
        currencyCode: 'USD',
      })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('POST /v1/payments/send — rejects insufficient funds', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${sender.accessToken}`)
      .send({
        recipient: 'receiver@amixpay.test',
        amount: 999999,
        currencyCode: 'USD',
      });

    // Should fail — either 400 from amount validation or 500 from insufficient funds
    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  test('POST /v1/payments/send — rejects non-existent recipient', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${sender.accessToken}`)
      .send({
        recipient: 'nobody_exists@amixpay.test',
        amount: 10,
        currencyCode: 'USD',
      })
      .expect(404);

    expect(res.body.success).toBe(false);
  });

  test('POST /v1/payments/send — rejects zero amount', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${sender.accessToken}`)
      .send({
        recipient: 'receiver@amixpay.test',
        amount: 0,
        currencyCode: 'USD',
      })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  test('POST /v1/payments/send — rejects negative amount', async () => {
    const res = await request(app)
      .post('/v1/payments/send')
      .set('Authorization', `Bearer ${sender.accessToken}`)
      .send({
        recipient: 'receiver@amixpay.test',
        amount: -50,
        currencyCode: 'USD',
      })
      .expect(400);

    expect(res.body.success).toBe(false);
  });
});
