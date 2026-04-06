# Velocash - System Architecture

## 1. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                  Flutter Mobile App                           │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐  │  │
│  │  │  Wallet   │ │ Payments │ │ Transfers│ │  QR Scanner    │  │  │
│  │  │  Module   │ │  Module  │ │  Module  │ │   Module       │  │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────────────┘  │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐  │  │
│  │  │  Auth     │ │ Contacts │ │ Notif.   │ │  Profile       │  │  │
│  │  │  Module   │ │  Module  │ │  Module  │ │   Module       │  │  │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────────┘
                             │ HTTPS / WSS
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS CLOUD                                    │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                  AWS CloudFront (CDN)                         │  │
│  └──────────────────────────┬────────────────────────────────────┘  │
│                              │                                      │
│  ┌───────────────────────────▼──────────────────────────────────┐  │
│  │              AWS API Gateway + WAF                            │  │
│  │         Rate Limiting / IP Filtering / DDoS                   │  │
│  └──────────────────────────┬────────────────────────────────────┘  │
│                              │                                      │
│  ┌───────────────────────────▼──────────────────────────────────┐  │
│  │           Application Load Balancer (ALB)                     │  │
│  └───────┬──────────┬───────────┬──────────┬────────────────────┘  │
│          │          │           │          │                        │
│          ▼          ▼           ▼          ▼                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              ECS Fargate Cluster (Auto-scaling)              │   │
│  │                                                              │   │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │   │
│  │  │   Auth     │ │  Payment   │ │  Transfer  │              │   │
│  │  │  Service   │ │  Service   │ │  Service   │              │   │
│  │  │ (Node/Exp) │ │ (Node/Exp) │ │ (Node/Exp) │              │   │
│  │  └────────────┘ └────────────┘ └────────────┘              │   │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │   │
│  │  │  Wallet    │ │    QR      │ │Notification│              │   │
│  │  │  Service   │ │  Service   │ │  Service   │              │   │
│  │  │ (Node/Exp) │ │ (Node/Exp) │ │ (Node/Exp) │              │   │
│  │  └────────────┘ └────────────┘ └────────────┘              │   │
│  │  ┌────────────┐ ┌────────────┐                              │   │
│  │  │   User     │ │  Currency  │                              │   │
│  │  │  Service   │ │  Service   │                              │   │
│  │  │ (Node/Exp) │ │ (Node/Exp) │                              │   │
│  │  └────────────┘ └────────────┘                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│          │          │           │          │                        │
│          ▼          ▼           ▼          ▼                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    DATA LAYER                                │   │
│  │                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │   │
│  │  │ RDS PostgreSQL│  │ ElastiCache  │  │    Amazon SQS    │  │   │
│  │  │  (Primary +   │  │   (Redis)    │  │  (Event Queue)   │  │   │
│  │  │   Read Replica)│  │  Sessions/   │  │  Async Tasks     │  │   │
│  │  │              │  │  Rate Limits  │  │                  │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │   │
│  │                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │   │
│  │  │   S3         │  │  AWS KMS     │  │  AWS Secrets     │  │   │
│  │  │  (Documents/ │  │ (Encryption  │  │   Manager        │  │   │
│  │  │   QR Codes)  │  │   Keys)      │  │                  │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 EXTERNAL INTEGRATIONS                        │   │
│  │                                                              │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │   │
│  │  │  Stripe  │ │  SWIFT   │ │  Twilio  │ │  SendGrid    │  │   │
│  │  │ Payments │ │  Network │ │   SMS    │ │   Email      │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────────────────────┐   │   │
│  │  │ Open     │ │ Firebase │ │  AWS SNS (Push Notif.)   │   │   │
│  │  │ Exchange │ │   Auth   │ │                          │   │   │
│  │  │ Rates API│ │  (Social)│ │                          │   │   │
│  │  └──────────┘ └──────────┘ └──────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 MONITORING & OBSERVABILITY                   │   │
│  │  CloudWatch │ X-Ray │ CloudTrail │ GuardDuty                │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Service Responsibilities

| Service | Responsibility |
|---------|---------------|
| **Auth Service** | Registration, login, JWT issuance/refresh, 2FA, password reset, session management |
| **User Service** | Profile CRUD, username lookup, phone/email verification, KYC status |
| **Wallet Service** | Balance management, multi-currency wallets, ledger entries, funding/withdrawal |
| **Payment Service** | Send money, request money, username/phone/email payments, payment resolution |
| **Transfer Service** | International transfers, FX conversion, SWIFT integration, compliance checks |
| **QR Service** | QR code generation, QR payment parsing, merchant QR flows |
| **Notification Service** | Push notifications, SMS, email, in-app notifications |
| **Currency Service** | Exchange rate fetching, rate caching, conversion logic, supported currency management |

### Inter-Service Communication

- **Synchronous**: REST over internal ALB for request/response flows (e.g., Wallet Service checking balance during payment)
- **Asynchronous**: Amazon SQS for event-driven flows (e.g., Payment Service emitting `payment.completed` for Notification Service to consume)

---

## 2. Database Structure

### Entity Relationship Diagram

```
┌──────────────────┐       ┌──────────────────────┐
│      users       │       │    user_devices       │
├──────────────────┤       ├──────────────────────┤
│ id (PK, UUID)    │──┐    │ id (PK, UUID)        │
│ username (UQ)    │  │    │ user_id (FK)         │
│ email (UQ)       │  │    │ device_token         │
│ phone (UQ)       │  │    │ platform             │
│ password_hash    │  │    │ last_active_at       │
│ first_name       │  │    │ created_at           │
│ last_name        │  └───>│                      │
│ date_of_birth    │       └──────────────────────┘
│ country_code     │
│ kyc_status       │       ┌──────────────────────┐
│ kyc_level        │       │   two_factor_auth    │
│ status           │       ├──────────────────────┤
│ two_factor_on    │       │ id (PK, UUID)        │
│ avatar_url       │  ┌───>│ user_id (FK, UQ)     │
│ created_at       │──┘    │ method (totp|sms)    │
│ updated_at       │       │ secret_encrypted     │
└──────────────────┘       │ backup_codes_enc     │
        │                  │ enabled_at           │
        │                  └──────────────────────┘
        │
        │  1:N
        ▼
┌──────────────────┐       ┌──────────────────────┐
│     wallets      │       │  wallet_currencies   │
├──────────────────┤       ├──────────────────────┤
│ id (PK, UUID)    │──┐    │ id (PK, UUID)        │
│ user_id (FK)     │  │    │ wallet_id (FK)       │
│ primary_currency │  └───>│ currency_code        │
│ status           │       │ balance              │
│ created_at       │       │ available_balance    │
│ updated_at       │       │ pending_balance      │
│                  │       │ updated_at           │
└──────────────────┘       └──────────────────────┘
        │
        │  1:N
        ▼
┌──────────────────────────────────────────────────┐
│                  transactions                     │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ wallet_id (FK)                                   │
│ type (send|receive|request|qr|transfer|fund|     │
│       withdraw)                                   │
│ status (pending|processing|completed|failed|      │
│         cancelled|expired)                        │
│ amount                                            │
│ currency_code                                     │
│ fee_amount                                        │
│ fee_currency                                      │
│ exchange_rate (nullable)                          │
│ reference_id (UQ)                                 │
│ description                                       │
│ metadata (JSONB)                                  │
│ created_at                                        │
│ updated_at                                        │
└──────────────────────────────────────────────────┘
        │
        │
        ▼
┌──────────────────────────────────────────────────┐
│                   ledger_entries                   │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ transaction_id (FK)                              │
│ wallet_currency_id (FK)                          │
│ entry_type (debit|credit)                        │
│ amount                                            │
│ balance_after                                     │
│ created_at                                        │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                    payments                       │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ transaction_id (FK)                              │
│ sender_id (FK -> users)                          │
│ recipient_id (FK -> users, nullable)             │
│ payment_method (username|phone|email|qr)         │
│ recipient_identifier                              │
│ amount                                            │
│ currency_code                                     │
│ status                                            │
│ note                                              │
│ resolved_at                                       │
│ expires_at                                        │
│ created_at                                        │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                payment_requests                   │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ requester_id (FK -> users)                       │
│ payer_id (FK -> users, nullable)                 │
│ payer_identifier                                  │
│ payer_method (username|phone|email)               │
│ amount                                            │
│ currency_code                                     │
│ status (pending|accepted|declined|expired)        │
│ note                                              │
│ payment_id (FK -> payments, nullable)             │
│ expires_at                                        │
│ created_at                                        │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│              international_transfers              │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ transaction_id (FK)                              │
│ sender_id (FK -> users)                          │
│ recipient_name                                    │
│ recipient_bank_encrypted                          │
│ recipient_account_encrypted                       │
│ recipient_country                                 │
│ swift_code                                        │
│ source_currency                                   │
│ target_currency                                   │
│ source_amount                                     │
│ target_amount                                     │
│ exchange_rate                                     │
│ fee_amount                                        │
│ status (pending|compliance_review|processing|     │
│         sent|completed|failed|returned)           │
│ compliance_status                                 │
│ external_reference                                │
│ estimated_arrival                                 │
│ created_at                                        │
│ updated_at                                        │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                   qr_codes                        │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ user_id (FK)                                     │
│ type (static|dynamic)                            │
│ amount (nullable, for dynamic)                   │
│ currency_code (nullable)                         │
│ payload_encrypted                                 │
│ is_active                                         │
│ usage_count                                       │
│ max_uses (nullable)                               │
│ expires_at (nullable)                             │
│ created_at                                        │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│               exchange_rates                      │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ source_currency                                   │
│ target_currency                                   │
│ rate                                              │
│ spread                                            │
│ provider                                          │
│ fetched_at                                        │
│ expires_at                                        │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│              supported_currencies                 │
├──────────────────────────────────────────────────┤
│ code (PK, VARCHAR(3))                            │
│ name                                              │
│ symbol                                            │
│ decimal_places                                    │
│ is_active                                         │
│ min_send_amount                                   │
│ max_send_amount                                   │
│ transfer_enabled                                  │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                notifications                      │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ user_id (FK)                                     │
│ type (payment|request|transfer|security|system)  │
│ title                                             │
│ body                                              │
│ data (JSONB)                                      │
│ read_at (nullable)                                │
│ created_at                                        │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                 audit_logs                        │
├──────────────────────────────────────────────────┤
│ id (PK, UUID)                                    │
│ user_id (FK, nullable)                           │
│ action                                            │
│ resource_type                                     │
│ resource_id                                       │
│ ip_address                                        │
│ user_agent                                        │
│ metadata (JSONB)                                  │
│ created_at                                        │
└──────────────────────────────────────────────────┘
```

### Key Database Design Decisions

1. **Double-entry ledger** (`ledger_entries`): Every money movement creates a debit and credit pair, ensuring the system is always balanced and fully auditable.

2. **Separate `wallet_currencies`**: One wallet holds multiple currency sub-accounts. Balances split into `balance`, `available_balance`, and `pending_balance` to handle holds during processing.

3. **Encrypted sensitive fields**: Bank account numbers, TOTP secrets, and QR payloads stored encrypted at the application layer using AWS KMS envelope encryption.

4. **JSONB metadata**: Flexible metadata on transactions allows storing payment-method-specific details without schema changes.

5. **All monetary values**: Stored as `DECIMAL(19,4)` to avoid floating-point errors. Application logic uses the `decimal_places` from `supported_currencies` for display.

### Key Indexes

```sql
-- High-frequency lookups
CREATE UNIQUE INDEX idx_users_username ON users (username);
CREATE UNIQUE INDEX idx_users_email ON users (email);
CREATE UNIQUE INDEX idx_users_phone ON users (phone);
CREATE INDEX idx_wallets_user_id ON wallets (user_id);
CREATE INDEX idx_wallet_currencies_wallet ON wallet_currencies (wallet_id, currency_code);
CREATE INDEX idx_transactions_wallet ON transactions (wallet_id, created_at DESC);
CREATE INDEX idx_transactions_reference ON transactions (reference_id);
CREATE INDEX idx_payments_sender ON payments (sender_id, created_at DESC);
CREATE INDEX idx_payments_recipient ON payments (recipient_id, created_at DESC);
CREATE INDEX idx_payment_requests_payer ON payment_requests (payer_id, status);
CREATE INDEX idx_intl_transfers_sender ON international_transfers (sender_id, created_at DESC);
CREATE INDEX idx_notifications_user ON notifications (user_id, read_at, created_at DESC);
CREATE INDEX idx_audit_logs_user ON audit_logs (user_id, created_at DESC);
CREATE INDEX idx_exchange_rates_pair ON exchange_rates (source_currency, target_currency, fetched_at DESC);
```

---

## 3. API Structure

Base URL: `https://api.velocash.com/v1`

### Authentication Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Create new user account |
| POST | `/auth/login` | Login, returns access + refresh tokens |
| POST | `/auth/refresh` | Refresh access token |
| POST | `/auth/logout` | Revoke refresh token |
| POST | `/auth/forgot-password` | Send password reset email |
| POST | `/auth/reset-password` | Reset password with token |
| POST | `/auth/verify-email` | Verify email address |
| POST | `/auth/verify-phone` | Verify phone via OTP |

### Two-Factor Authentication

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/2fa/enable` | Enable 2FA (returns QR/secret) |
| POST | `/auth/2fa/verify` | Verify 2FA code during enable |
| POST | `/auth/2fa/disable` | Disable 2FA (requires current code) |
| POST | `/auth/2fa/challenge` | Submit 2FA code during login |

### User Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/me` | Get current user profile |
| PATCH | `/users/me` | Update profile |
| PUT | `/users/me/avatar` | Upload avatar |
| GET | `/users/lookup` | Lookup user by username, phone, or email |
| POST | `/users/me/kyc` | Submit KYC documents |
| GET | `/users/me/kyc/status` | Get KYC verification status |

### Wallet Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/wallets` | Get user's wallet with all currency balances |
| POST | `/wallets/currencies` | Add a currency to wallet |
| DELETE | `/wallets/currencies/:code` | Remove a currency (must have zero balance) |
| GET | `/wallets/transactions` | List transactions (paginated, filterable) |
| GET | `/wallets/transactions/:id` | Get transaction details |
| POST | `/wallets/fund` | Fund wallet (link external source) |
| POST | `/wallets/withdraw` | Withdraw to external account |

### Payment Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/payments/send` | Send money to a user |
| GET | `/payments/:id` | Get payment details |
| POST | `/payments/cancel/:id` | Cancel pending payment |

**Send money request body:**
```json
{
  "method": "username | phone | email",
  "recipient": "@janedoe | +1555... | jane@...",
  "amount": 50.00,
  "currency": "USD",
  "note": "Lunch money"
}
```

### Payment Request Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/payment-requests` | Request money from a user |
| GET | `/payment-requests` | List incoming/outgoing requests |
| GET | `/payment-requests/:id` | Get request details |
| POST | `/payment-requests/:id/accept` | Accept and pay a request |
| POST | `/payment-requests/:id/decline` | Decline a request |
| POST | `/payment-requests/:id/cancel` | Cancel own request |

### QR Payment Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/qr/generate` | Generate a QR code (static or with amount) |
| POST | `/qr/parse` | Parse a scanned QR payload |
| POST | `/qr/pay` | Execute payment from scanned QR |
| GET | `/qr/my-codes` | List user's generated QR codes |
| DELETE | `/qr/:id` | Deactivate a QR code |

### International Transfer Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/transfers/international` | Initiate international transfer |
| GET | `/transfers/international/:id` | Get transfer status/tracking |
| GET | `/transfers/international` | List user's transfers |
| POST | `/transfers/international/quote` | Get fee + rate quote before sending |
| GET | `/transfers/international/countries` | List supported destination countries |

**Quote request:**
```json
{
  "source_currency": "USD",
  "target_currency": "EUR",
  "amount": 1000.00,
  "destination_country": "DE"
}
```

**Quote response:**
```json
{
  "source_amount": 1000.00,
  "target_amount": 921.50,
  "exchange_rate": 0.9250,
  "fee": 3.50,
  "estimated_arrival": "2026-03-14T12:00:00Z",
  "quote_expires_at": "2026-03-12T12:30:00Z"
}
```

### Currency Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/currencies` | List supported currencies |
| GET | `/currencies/rates` | Get exchange rates for a base currency |
| POST | `/currencies/convert` | Convert between currencies in wallet |

### Notification Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/notifications` | List notifications (paginated) |
| PATCH | `/notifications/:id/read` | Mark as read |
| POST | `/notifications/read-all` | Mark all as read |
| PUT | `/notifications/settings` | Update push/email/SMS preferences |
| POST | `/notifications/devices` | Register device for push notifications |

### Standard Response Envelope

```json
{
  "success": true,
  "data": { },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

### Error Response

```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_BALANCE",
    "message": "Your USD balance is insufficient for this transaction.",
    "details": {}
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request body |
| `UNAUTHORIZED` | 401 | Missing/invalid token |
| `TWO_FACTOR_REQUIRED` | 403 | 2FA challenge needed |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RECIPIENT_NOT_FOUND` | 404 | Payment recipient not resolved |
| `INSUFFICIENT_BALANCE` | 422 | Not enough funds |
| `CURRENCY_NOT_SUPPORTED` | 422 | Currency not available |
| `KYC_REQUIRED` | 422 | KYC verification needed for this action |
| `TRANSFER_LIMIT_EXCEEDED` | 422 | Daily/monthly limit reached |
| `DUPLICATE_TRANSACTION` | 409 | Idempotency key conflict |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

### Middleware Pipeline

```
Request
  → Rate Limiter (Redis-backed, per-user + per-IP)
  → Request ID (UUID for tracing)
  → Body Parser + Validation (Joi/Zod schemas)
  → JWT Authentication
  → 2FA Gate (for sensitive operations)
  → KYC Level Check (for transfers)
  → Idempotency Check (for mutations)
  → Controller → Service → Repository
  → Response Serializer
  → Audit Logger
```

---

## 4. Security Architecture

### 4.1 Authentication Flow

```
┌────────┐                    ┌────────────┐                  ┌────────┐
│ Client │                    │Auth Service│                  │  Redis │
└───┬────┘                    └─────┬──────┘                  └───┬────┘
    │  POST /auth/login             │                             │
    │  {email, password}            │                             │
    │──────────────────────────────>│                             │
    │                               │  Verify password (bcrypt)   │
    │                               │──────────────────────>      │
    │                               │                             │
    │   IF 2FA enabled:             │                             │
    │   {requires_2fa: true,        │                             │
    │    challenge_token}           │                             │
    │<──────────────────────────────│                             │
    │                               │                             │
    │  POST /auth/2fa/challenge     │                             │
    │  {challenge_token, code}      │                             │
    │──────────────────────────────>│                             │
    │                               │  Verify TOTP/SMS code       │
    │                               │──────────────────────>      │
    │                               │                             │
    │   {access_token (15m),        │  Store refresh token        │
    │    refresh_token (30d)}       │────────────────────────────>│
    │<──────────────────────────────│                             │
    │                               │                             │
    │  GET /wallets                  │                             │
    │  Authorization: Bearer <at>   │                             │
    │──────────────────────────────>│  Validate JWT               │
    │                               │                             │
    │   {wallet data}               │                             │
    │<──────────────────────────────│                             │
```

### 4.2 JWT Token Design

**Access Token (short-lived, 15 minutes):**
```json
{
  "sub": "user-uuid",
  "iat": 1710244800,
  "exp": 1710245700,
  "jti": "unique-token-id",
  "scope": "user",
  "kyc_level": 2,
  "device_id": "device-uuid"
}
```

**Refresh Token (long-lived, 30 days):**
- Stored in Redis with user/device binding
- Rotated on every use (one-time use)
- Revocation via Redis deletion
- Family tracking: if a used refresh token is reused, revoke entire family (stolen token detection)

### 4.3 Encryption Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                  ENCRYPTION LAYERS                           │
│                                                              │
│  LAYER 1: Transport                                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ TLS 1.3 everywhere (client ↔ API, service ↔ service,  │  │
│  │ service ↔ database). Certificate pinning in Flutter.   │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 2: Application (Envelope Encryption via AWS KMS)      │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Encrypted fields: bank account numbers, SWIFT codes,   │  │
│  │ TOTP secrets, QR payloads, backup codes.               │  │
│  │                                                        │  │
│  │ Process:                                               │  │
│  │ 1. Request data encryption key (DEK) from KMS          │  │
│  │ 2. Encrypt field with DEK (AES-256-GCM)               │  │
│  │ 3. Store encrypted DEK alongside encrypted data        │  │
│  │ 4. KMS master key never leaves AWS                     │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 3: Database                                           │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ RDS encryption at rest (AES-256). Encrypted snapshots  │  │
│  │ and backups. SSL-only connections enforced.             │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  LAYER 4: Client                                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Flutter secure storage for tokens (Keychain / Keystore)│  │
│  │ No sensitive data in shared preferences.               │  │
│  │ Biometric lock for app access.                         │  │
│  └────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.4 Security Controls Summary

| Control | Implementation |
|---------|---------------|
| **Password hashing** | bcrypt with cost factor 12 |
| **2FA** | TOTP (RFC 6238) via authenticator app, SMS fallback via Twilio |
| **Rate limiting** | Redis sliding window: 100 req/min general, 5 req/min login, 3 req/min 2FA |
| **Idempotency** | Client-generated `Idempotency-Key` header on all mutations, stored 24h in Redis |
| **Input validation** | Zod schemas on every endpoint, SQL parameterized queries (no raw SQL) |
| **CSRF** | Not applicable (token-based API, no cookies for auth) |
| **Certificate pinning** | SHA-256 pin of API certificate in Flutter HTTP client |
| **Device binding** | Refresh tokens bound to device ID; new device triggers re-authentication |
| **Transaction signing** | Sensitive operations (send > $500, international transfers) require PIN or biometric re-confirmation |
| **Fraud detection** | Rule engine flags: unusual amount, new recipient, velocity check, geo mismatch |
| **Audit trail** | Every state change logged to `audit_logs` with user, IP, action, timestamp |
| **Secrets management** | AWS Secrets Manager for API keys, DB credentials; rotated automatically |
| **Network security** | VPC with private subnets for services/DB. No public DB access. Security groups with least-privilege rules |
| **DDoS protection** | AWS WAF + Shield on API Gateway + CloudFront |
| **Dependency scanning** | `npm audit` in CI/CD pipeline, automated Dependabot PRs |
| **KYC tiers** | Tier 1 (email/phone verified): $500/day limit. Tier 2 (ID verified): $5,000/day. Tier 3 (enhanced): $50,000/day |

### 4.5 Sensitive Operation Re-authentication

Operations that require stepping up security beyond the base JWT:

```
HIGH SENSITIVITY (require PIN/biometric + fresh 2FA):
  - International transfers
  - Withdrawals to external bank
  - Change password
  - Disable 2FA
  - Change email/phone

MEDIUM SENSITIVITY (require PIN/biometric):
  - Send money > $500
  - Add new bank account
  - Generate static QR code

STANDARD (JWT only):
  - View balances
  - View transaction history
  - Send money ≤ $500 to existing contacts
  - Request money
```

### 4.6 Data Flow: Send Money via Username

```
1. Client: POST /payments/send
   {method: "username", recipient: "@janedoe", amount: 50, currency: "USD"}
   Headers: Authorization: Bearer <jwt>, Idempotency-Key: <uuid>

2. API Gateway: WAF check → Rate limit → Forward

3. Payment Service:
   a. Validate JWT, extract user_id
   b. Check idempotency key in Redis
   c. Call User Service: resolve "@janedoe" → recipient user_id
   d. Call Wallet Service: check sender USD balance ≥ 50.00
   e. BEGIN TRANSACTION (Serializable isolation)
      - Debit sender wallet_currencies (USD) by 50.00
      - Credit recipient wallet_currencies (USD) by 50.00
      - Insert transaction record (sender side, type=send)
      - Insert transaction record (recipient side, type=receive)
      - Insert ledger_entries (debit + credit pair)
      - Insert payment record
   f. COMMIT
   g. Store idempotency result in Redis (TTL 24h)
   h. Emit event to SQS: payment.completed

4. Notification Service (async, from SQS):
   a. Send push notification to recipient
   b. Send push notification to sender (confirmation)
   c. Store notification records

5. Response to client:
   {success: true, data: {payment_id, status: "completed", ...}}
```

---

## 5. Flutter App Architecture

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/             # Environment config, API URLs
│   ├── constants/           # App-wide constants
│   ├── errors/              # Custom exception classes
│   ├── network/             # Dio HTTP client, interceptors, certificate pinning
│   ├── security/            # Secure storage, biometric, PIN
│   ├── routing/             # GoRouter configuration
│   └── theme/               # App theme, colors, typography
├── features/
│   ├── auth/
│   │   ├── data/            # AuthRepository, AuthRemoteDataSource
│   │   ├── domain/          # AuthEntity, LoginUseCase, RegisterUseCase
│   │   └── presentation/   # LoginScreen, RegisterScreen, TwoFactorScreen
│   ├── wallet/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/   # WalletScreen, BalanceCard, CurrencyList
│   ├── payments/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/   # SendScreen, RecipientPicker, ConfirmSheet
│   ├── requests/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/   # RequestScreen, IncomingRequests
│   ├── qr/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/   # QRScannerScreen, QRGenerateScreen
│   ├── transfers/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/   # TransferScreen, QuoteCard, TrackingScreen
│   ├── notifications/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/   # NotificationList, NotificationDetail
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/   # ProfileScreen, KYCScreen, SettingsScreen
└── shared/
    ├── widgets/             # Reusable UI components
    ├── extensions/          # Dart extensions
    └── utils/               # Formatters, validators
```

**State Management**: Riverpod (compile-safe, testable, supports code generation)

**Key Flutter Packages**:
- `dio` + `dio_smart_retry` - HTTP client with retry logic
- `flutter_riverpod` - State management
- `go_router` - Declarative routing
- `flutter_secure_storage` - Token/PIN storage
- `local_auth` - Biometric authentication
- `mobile_scanner` - QR code scanning
- `qr_flutter` - QR code generation
- `intl` - Currency formatting and localization
- `freezed` - Immutable data classes

---

## 6. Infrastructure (AWS)

```
Region: us-east-1 (primary), eu-west-1 (DR)

Compute:      ECS Fargate (auto-scaling 2-20 tasks per service)
Database:     RDS PostgreSQL 16 (db.r6g.xlarge, Multi-AZ, 1 read replica)
Cache:        ElastiCache Redis 7 (cache.r6g.large, cluster mode)
Queue:        Amazon SQS (Standard queues, DLQ for failed messages)
Storage:      S3 (QR images, KYC documents, avatars)
CDN:          CloudFront (static assets, QR code images)
API:          API Gateway (REST, throttling, API keys for versioning)
Secrets:      AWS Secrets Manager (DB creds, API keys, auto-rotation)
Encryption:   AWS KMS (CMK for envelope encryption)
DNS:          Route 53 (failover routing)
Monitoring:   CloudWatch (metrics, alarms), X-Ray (distributed tracing)
Logging:      CloudWatch Logs → S3 (long-term) → Athena (ad-hoc queries)
CI/CD:        GitHub Actions → ECR → ECS rolling deploy
Security:     WAF, Shield, GuardDuty, Security Hub
Compliance:   CloudTrail (API audit), AWS Config (resource compliance)
```
