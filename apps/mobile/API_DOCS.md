# AmixPay REST API Documentation

**Base URL:** `http://localhost:3000/v1` (dev) | `https://api.amixpay.com/v1` (prod)

All responses follow the format:
```json
{ "success": true, "data": { ... } }
{ "success": false, "error": { "code": "ERROR_CODE", "message": "Description" } }
```

**Authentication:** `Authorization: Bearer <access_token>` (all protected routes)

---

## Authentication

### POST /auth/register
Register a new user.

**Body:**
```json
{
  "email": "alice@example.com",
  "password": "Password123!",
  "firstName": "Alice",
  "lastName": "Johnson",
  "username": "alice",
  "phone": "+14155551234",
  "countryCode": "US"
}
```

**Response:** `201`
```json
{
  "user": { "id": "uuid", "email": "alice@example.com", "username": "alice" },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5...",
  "refreshToken": "a1b2c3d4...",
  "expiresIn": 900
}
```

### POST /auth/login
```json
{ "email": "alice@example.com", "password": "Password123!" }
```
Response: same as register. If 2FA enabled, returns `{ "requiresTwoFactor": true, "challengeToken": "..." }`

### POST /auth/refresh
```json
{ "refreshToken": "a1b2c3d4..." }
```

### POST /auth/logout
Auth required. Body: `{ "refreshToken": "..." }`

### POST /auth/2fa/enable
Auth required. Returns: `{ "secret": "BASE32SECRET", "qrUrl": "otpauth://totp/..." }`

### POST /auth/2fa/verify
Auth required. Body: `{ "code": "123456" }` — Activates 2FA, returns backup codes.

### POST /auth/2fa/challenge
Body: `{ "challengeToken": "...", "code": "123456" }`

---

## Users

### GET /users/me
Returns current user profile.

### PATCH /users/me
Update profile: `{ "firstName", "lastName", "phone", "dateOfBirth", "countryCode" }`

### GET /users/lookup?q=alice
Lookup user by username, email, or phone. Returns public profile.

### POST /users/me/kyc
Submit KYC document: `{ "type": "passport", "s3Key": "kyc/user-id/passport-front.jpg" }`

### GET /users/me/kyc/status
Returns `{ "status": "approved", "level": 2, "documents": [...] }`

---

## Wallets

### GET /wallets
Full wallet with all currency balances.

**Response:**
```json
{
  "id": "wallet-uuid",
  "user_id": "user-uuid",
  "primary_currency": "USD",
  "currencies": [
    { "currency_code": "USD", "balance": "5000.00", "available_balance": "5000.00" },
    { "currency_code": "EUR", "balance": "1200.00", "available_balance": "1200.00" }
  ]
}
```

### POST /wallets/currencies
Add currency: `{ "currencyCode": "GBP" }`

### DELETE /wallets/currencies/:code
Remove currency (only if balance is 0).

### GET /wallets/transactions
Query: `?limit=20&offset=0&type=send&currency=USD`

### GET /wallets/transactions/:id

---

## Payments

### POST /payments/send
```json
{
  "recipient": "bob@example.com",
  "amount": 150.00,
  "currencyCode": "USD",
  "note": "Dinner split"
}
```
Returns sender transaction + recipient transaction + payment record.

**Fee:** 0.5% of amount.

### GET /payments/:id

### POST /payments/cancel/:id

---

## Payment Requests

### POST /payment-requests
```json
{
  "payer": "bob",
  "amount": 50.00,
  "currencyCode": "USD",
  "note": "Coffee"
}
```

### GET /payment-requests?role=all|requester|payer

### POST /payment-requests/:id/accept
Deducts from payer's wallet and credits requester.

### POST /payment-requests/:id/decline
### POST /payment-requests/:id/cancel

---

## International Transfers

### POST /transfers/international/quote
```json
{
  "sourceCurrency": "USD",
  "targetCurrency": "GBP",
  "sourceAmount": 1000
}
```
Returns: `{ "rate": 0.79, "fee": 5.99, "targetAmount": 784.01, "estimatedDelivery": "..." }`

### POST /transfers/international
```json
{
  "quoteId": "...",
  "sourceAmount": 1000,
  "sourceCurrency": "USD",
  "targetCurrency": "GBP",
  "targetAmount": 784.01,
  "rate": 0.79,
  "fee": 5.99,
  "recipientDetails": {
    "name": "Bob Smith",
    "accountNumber": "12345678",
    "routingNumber": "021000021",
    "iban": "GB29NWBK60161331926819",
    "bankName": "Barclays",
    "country": "GB"
  }
}
```

### GET /transfers/international
### GET /transfers/international/:id
### POST /transfers/international/quote (see above)
### GET /transfers/international/countries

---

## Currencies

### GET /currencies
Returns list of 16 supported currencies with code, name, symbol, flag.

### GET /currencies/rates?base=USD
Returns real-time exchange rates (cached 10 min from Open Exchange Rates).

### POST /currencies/convert
```json
{ "amount": 100, "from": "USD", "to": "EUR" }
```
Returns: `{ "amount": 92.40, "rate": 0.924, "fee": 0.18 }`

---

## QR Codes

### POST /qr/generate
```json
{ "amount": 25.00, "currency": "USD", "description": "Coffee" }
```
Returns: `{ "codeId": "...", "dataUrl": "data:image/png;base64,...", "payload": {...} }`

### POST /qr/parse
```json
{ "payload": "{...json string...}" }
```

### POST /qr/pay
```json
{ "payload": "{...}", "amount": 25.00, "currency": "USD" }
```

### GET /qr/my-codes
### DELETE /qr/:id

---

## Funding

### POST /funding/bank-accounts/link-token
Returns Plaid link token for bank connection.

### POST /funding/bank-accounts
```json
{ "publicToken": "plaid-public-token-..." }
```

### GET /funding/bank-accounts

### POST /funding/deposit
```json
{ "amount": 500.00, "currency": "USD" }
```
Returns Stripe PaymentIntent `clientSecret` for card payment.

### POST /funding/deposit/confirm
```json
{ "paymentIntentId": "pi_..." }
```
Credits wallet after successful Stripe payment.

### GET /funding/transactions

---

## Virtual Cards (Stripe Issuing)

### POST /virtual-cards
```json
{
  "cardHolderName": "Alice Johnson",
  "currency": "USD",
  "spendingLimit": 1000.00
}
```

### GET /virtual-cards
### GET /virtual-cards/:id
### PATCH /virtual-cards/:id — `{ "status": "frozen" | "active" }`
### DELETE /virtual-cards/:id — Cancels card permanently
### GET /virtual-cards/:id/transactions

---

## Notifications

### GET /notifications?limit=20&offset=0
### PATCH /notifications/:id/read
### POST /notifications/read-all
### GET /notifications/settings
### PUT /notifications/settings
### POST /notifications/devices
```json
{ "deviceToken": "fcm-token...", "platform": "android", "deviceName": "Pixel 7" }
```

---

## Merchants

### POST /merchants/register
```json
{
  "businessName": "Alice's Coffee",
  "businessType": "food_beverage",
  "websiteUrl": "https://alicescoffee.com"
}
```

### GET /merchants/me — Dashboard with stats
### PATCH /merchants/me
### GET /merchants/payments?status=completed
### POST /merchants/checkout-link
### GET /merchants/checkout-link/:slug — Public endpoint
### GET /merchants/stripe/connect — Returns Stripe Connect onboarding URL

---

## Splits

### POST /splits
```json
{
  "title": "Dinner at Sakura",
  "currencyCode": "USD",
  "participants": ["bob@example.com", "charlie"],
  "items": [
    { "name": "Beef Teriyaki Bowl", "price": 4.50, "qty": 1 },
    { "name": "Salmon Sashimi Plate", "price": 4.80, "qty": 1 }
  ],
  "taxAmount": 2.38,
  "discountAmount": 2.00
}
```

### GET /splits
### GET /splits/:id
### POST /splits/:id/pay — Pay your share
### POST /splits/:id/remind — Send reminders to unpaid members
### DELETE /splits/:id

---

## Admin (Admin role required)

### GET /admin/fraud/alerts?status=open&severity=high
### GET /admin/fraud/alerts/:id
### PATCH /admin/fraud/alerts/:id
```json
{ "status": "reviewed|blocked|dismissed", "notes": "..." }
```
### GET /admin/fraud/rules
### GET /admin/fraud/users?limit=20
### PATCH /admin/fraud/kyc/:documentId
```json
{ "action": "approve|reject", "level": 2, "reason": "..." }
```

---

## Exchange Rates

### GET /exchange-rates?base=USD
Live rates with 10-minute Redis cache.

---

## Stripe Webhooks

### POST /stripe/webhooks
Stripe sends events to this endpoint. Verifies signature with `STRIPE_WEBHOOK_SECRET`.

Events handled:
- `payment_intent.succeeded` — Confirm wallet credit
- `payment_intent.payment_failed` — Mark funding failed
- `issuing_transaction.created` — Track card spend

---

## Error Codes

| Code | HTTP | Description |
|---|---|---|
| `VALIDATION_ERROR` | 400 | Request body failed validation |
| `UNAUTHORIZED` | 401 | Missing/invalid/expired token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Duplicate resource (e.g., email exists) |
| `FRAUD_BLOCKED` | 403 | Transaction blocked by fraud detection |
| `INSUFFICIENT_FUNDS` | 422 | Not enough balance |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
