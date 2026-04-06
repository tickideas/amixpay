# AmixPay — Project Status

> Last updated: 6 April 2026

---

## What We Started With

Two separate repos (`amixpay-api` and `amixpay-app`) handed over from the previous developer. A Node.js/Express API deployed on Railway and a Flutter mobile app (v1.6.0). No tests, no CI/CD, several critical security gaps, and ~40% of the app's screens were UI-only with no backend support.

---

## ✅ Completed This Session

### 1. Monorepo Consolidation
- Merged two repos into single `apps/api` + `apps/mobile` structure
- Used the newer Flutter app (v1.6.0 over v1.2.0)
- Root `docker-compose.yml`, unified `.gitignore`, project `README.md`
- `packages/api-contract/` placeholder for future shared types
- `.github/workflows/` ready for CI
- Old repos backed up to `../amixpay-backup/`

### 2. Security Hardening (7 fixes)
| Fix | Details |
|---|---|
| JWT secret enforcement | Server crashes on startup if `JWT_SECRET` missing in production — no more `dev_secret_change_in_production` fallback |
| Stripe key removed from source | Was hardcoded in `main.dart`. Now requires `--dart-define=STRIPE_PK=pk_...` at build time |
| Demo mode restricted | Fake auth sessions only in `kDebugMode`. Release builds surface real errors |
| CORS locked down | Production rejects all cross-origin if `ALLOWED_ORIGINS` not set |
| Phone verification | Was auto-approving with no code. Now requires 6-digit OTP via `send-phone-otp` + `verify-phone` endpoints |
| TOTP encryption | 2FA secrets encrypted with AES-256-GCM before DB storage (was plaintext). Backward-compatible with legacy data |
| Amount validation | New `validateAmount` middleware — blocks NaN, Infinity, negative, dust (<0.01), hard cap at 1M, KYC-tier limits. Wired into payments + transfers |

### 3. CI/CD Pipeline
- GitHub Actions workflow (`.github/workflows/ci.yml`)
  - **API job**: spins up Postgres service container, runs migrations, runs Jest test suite
  - **Mobile job**: `flutter analyze` + `flutter test`
- Triggers on push to `main` and all PRs

### 4. Test Suite (40 API tests + Flutter model tests)
| Test file | Tests | What it covers |
|---|---|---|
| `auth.test.js` | 11 | Register, login, refresh token rotation, logout/blacklist, forgot password, duplicate email, weak password, missing fields |
| `wallet.test.js` | 5 | Get wallet, add currency, reject unsupported/duplicate currency, empty transaction list |
| `payments.test.js` | 6 | Send money, self-pay rejection, insufficient funds, non-existent recipient, zero/negative amounts |
| `validation.test.js` | 9 | NaN, Infinity, negative, dust amounts, KYC limits, absolute max cap, invalid email/username |
| `security.test.js` | 9 | Missing auth header, malformed JWT, expired JWT, protected route enforcement, password hash never leaked, health check, 404 handler, Helmet headers |
| `auth_models_test.dart` | 8 | UserModel parsing (snake_case + camelCase), roundtrip, defaults, AuthTokens parsing |

### 5. Database Performance (49 indexes)
- Migration `013_performance_indexes.js`
- Indexes on all foreign keys, status/type columns, `created_at` for sorting
- Covers: transactions, ledger_entries, payments, international_transfers, payment_requests, splits, notifications, fraud_alerts, virtual_cards, merchant_payments, zelle_transfers, banking_transactions, user_devices, kyc_documents

### 6. Dead-End Screens Eliminated

**New backend APIs built:**
| Feature | Endpoints | Migration |
|---|---|---|
| Savings Goals | `GET/POST /v1/savings`, `POST /:id/deposit`, `POST /:id/withdraw`, `DELETE /:id` | `014_savings_scheduled_referrals.js` |
| Scheduled Transfers | `GET/POST /v1/scheduled`, `PATCH /:id` (pause/resume), `DELETE /:id` | Same migration |
| Referrals | `GET /v1/referrals/my-code`, `GET /v1/referrals`, `POST /v1/referrals/apply`, `GET /v1/referrals/stats` | Same migration |

**New Flutter repositories:**
- `savings_repository.dart` — `SavingsGoalModel` + Riverpod provider
- `scheduled_repository.dart` — `ScheduledTransferModel` + Riverpod provider
- `referral_repository.dart` — `ReferralCode`, `ReferralFriend` models + providers
- `notifications_repository.dart` — `NotificationModel` + provider

**Wired to live data:**
- Currency converter → `ExchangeRateService` (Open Exchange Rates API) with offline fallback
- Home screen rate widget → live rates with cached/live status indicator

**Coming Soon (greyed out with banner):**
- Bill payments — "Coming soon — integrating with local providers"
- USDT/crypto wallet — "Coming soon — under development"

---

### 7. Dokploy Deployment Setup
- Production `Dockerfile` — multi-stage build, non-root user, health checks
- `docker-compose.prod.yml` — API + Postgres 15 + Redis 7, all env vars from Dokploy UI
- SSL opt-in (`DB_SSL=true`) instead of forced — no overhead for internal Docker connections
- `DEPLOY.md` — step-by-step Dokploy guide with env var reference, backup strategies, troubleshooting
- Railway references removed from config defaults

---

## 🔲 What's Left To Do

### High Priority

- [ ] **Set Dokploy env vars** — `JWT_SECRET`, `POSTGRES_PASSWORD`, `ALLOWED_ORIGINS` must be set. See `DEPLOY.md` for the full list. Server crashes without `JWT_SECRET`.
- [ ] **Deploy to Dokploy** — follow `DEPLOY.md`. Migrations run automatically on startup.
- [ ] **Sentry / monitoring** — no APM on either API or mobile app. Errors are invisible in production.
- [ ] **Wire savings/scheduled/referral screens to their new repositories** — the Flutter repositories exist but the screens still use local state. Each screen needs its `build()` method updated to `ref.watch()` the new providers.
- [ ] **Wire notifications screen to `notificationsProvider`** — repository exists, screen still shows empty state
- [ ] **Wire spending analytics to wallet transactions API** — screen uses local `transactionProvider`, should use `recentTransactionsProvider` from wallet_provider

### Medium Priority

- [ ] **Twilio SMS integration** — phone OTP endpoint logs codes to console. Wire to Twilio (env vars already exist in `.env.example`)
- [ ] **FCM push notifications** — Firebase is initialized in the app, device tokens are registered, but the API never actually sends push notifications
- [ ] **TypeScript migration for API** — plain JS with no type safety is risky for a fintech product
- [ ] **OpenAPI/Swagger spec** — formalize the API contract in `packages/api-contract/`
- [ ] **Proper KYC flow** — KYC screens exist but there's no document verification service (consider Onfido, Jumio, or Sumsub)
- [ ] **Audit logging** — every financial operation should write to an immutable audit table
- [ ] **Certificate pinning** — for the mobile app's API calls

### Low Priority / Future

- [ ] **Bill payments backend** — integrate Flutterwave Bills API for airtime, utilities, etc.
- [ ] **USDT/crypto wallet backend** — requires blockchain integration (Tron TRC-20 or similar)
- [ ] **Scheduled transfer execution** — the CRUD API exists but there's no cron/worker to actually execute transfers on schedule. Needs a job runner (Bull, Agenda, or a simple `setInterval` with DB polling).
- [ ] **Stripe Issuing for virtual cards** — the API code exists but needs Stripe Issuing approval
- [ ] **Staging environment** — separate Railway project with its own DB for pre-production testing
- [ ] **App Store / Play Store submission** — iOS build pipeline, provisioning profiles, store listings

---

## Git History

```
46cfa7e deploy: Dokploy setup — Dockerfile, production compose, deployment guide
04e66e8 docs: add STATUS.md — session progress and remaining work
0632884 feat: eliminate dead-end screens — add backend APIs + wire Flutter
f752dbe perf: add 49 database indexes across all tables
f8fd2f4 test: add CI pipeline + 40 API tests + Flutter model tests
febb3df security: critical hardening — JWT, TOTP encryption, CORS, input validation
021b2ff chore: remove old release keystore from tracking, clean up old repo dirs
a438149 chore: consolidate into monorepo
```

---

## Repo Structure

```
amixpay/
├── apps/
│   ├── api/                  ← Node.js / Express 5 / PostgreSQL / Redis
│   │   ├── src/
│   │   │   ├── routes/       ← 22 route files (auth, payments, wallets, etc.)
│   │   │   ├── services/     ← Business logic (auth, payment, transfer, fraud, etc.)
│   │   │   ├── middleware/   ← authenticate, validateAmount, rateLimiter, fraudCheck
│   │   │   ├── db/           ← 14 migrations, models, seeds
│   │   │   └── redis/        ← Redis client with in-memory fallback
│   │   ├── tests/            ← 5 test files, 40 tests
│   │   └── package.json
│   └── mobile/               ← Flutter 3.11+ / Riverpod / GoRouter / Dio
│       ├── lib/
│       │   ├── core/         ← API client, router, theme, services, storage
│       │   ├── features/     ← 20 feature modules (auth, wallet, payments, etc.)
│       │   └── shared/       ← Providers (auth, wallet, transaction), widgets
│       ├── test/             ← Model tests
│       └── pubspec.yaml
├── packages/
│   └── api-contract/         ← Future: shared OpenAPI spec
├── .github/workflows/ci.yml  ← GitHub Actions CI
├── docker-compose.yml         ← Postgres + Redis for local dev
├── STATUS.md                  ← This file
└── README.md
```
