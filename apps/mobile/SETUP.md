# AmixPay — Developer Setup Guide

## Project Overview

AmixPay is a global digital wallet and money transfer app (Flutter + Node.js backend).

| Part | Stack | Location |
|---|---|---|
| Mobile App | Flutter 3.41.4 + Riverpod + GoRouter + Dio | `AmixPAY/` |
| Backend API | Node.js + Express + PostgreSQL + Knex | `velocash-api/` |
| Database | PostgreSQL 15 (hosted on Railway) | Railway dashboard |
| Live API | `https://amixpay-api-production.up.railway.app` | Railway |

---

## Prerequisites

Install these before opening the project:

1. **Flutter 3.41.4** — already in `../flutter_windows_3.41.4-stable/flutter/bin/`
   - Add to PATH: `C:\Users\mcjam\Documents\APP BUILD 2026\flutter_windows_3.41.4-stable\flutter\bin`
2. **Android Studio** — for Android SDK and emulator
   - SDK location: `C:\Users\mcjam\AppData\Local\Android\Sdk`
3. **Node.js 20+** — for backend development
4. **Git** — for version control
5. **VS Code** — with Flutter + Dart extensions

---

## Open the Flutter App

```bash
# 1. Clone the repo
git clone https://github.com/AmizPay/amixpay-app.git
cd amixpay-app

# 2. Install dependencies
flutter pub get

# 3. Run on emulator (uses live API automatically)
flutter run --dart-define=API_URL=https://amixpay-api-production.up.railway.app/v1

# 4. Run on physical device
flutter run --dart-define=API_URL=https://amixpay-api-production.up.railway.app/v1
```

To open in VS Code:
1. `File` → `Open Folder` → select the `AmixPAY` folder
2. VS Code will detect Flutter and offer to get dependencies
3. Press `F5` to run (or use the Run menu)

---

## Open the Backend API

```bash
# 1. Clone the repo
git clone https://github.com/AmizPay/amixpay-api.git
cd amixpay-api

# 2. Install dependencies
npm install

# 3. Copy env template
cp .env.example .env
# Fill in your values in .env

# 4. Run locally (requires PostgreSQL + Redis running)
npm run dev
```

### Required Environment Variables (.env)

| Variable | Description | Where to get |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Railway → PostgreSQL → Connect |
| `JWT_SECRET` | 64-byte hex secret | `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"` |
| `JWT_ACCESS_EXPIRY` | Token expiry | Set to `15m` |
| `JWT_REFRESH_EXPIRY` | Refresh token expiry | Set to `30d` |
| `REDIS_URL` | Redis connection string | Railway → Redis → Connect |
| `STRIPE_SECRET_KEY` | Stripe payments | dashboard.stripe.com → API Keys |
| `FLW_SECRET_KEY` | Flutterwave payments | dashboard.flutterwave.com → Settings → API |
| `OPEN_EXCHANGE_RATES_KEY` | Currency exchange rates | openexchangerates.org |

---

## Project Structure — Flutter App

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + GoRouter + ProviderScope
├── core/
│   ├── network/api_client.dart  # Dio HTTP client (base URL, auth interceptor)
│   ├── router/                  # All app routes (GoRouter)
│   ├── theme/app_theme.dart     # Colors, text styles
│   └── storage/secure_storage.dart  # Encrypted local storage
├── features/
│   ├── auth/                    # Login, Register, 2FA, Email verification
│   ├── dashboard/               # Home screen, quick actions
│   ├── wallet/                  # Balances, transaction history
│   ├── payments/                # Send money, requests, confirm screen
│   ├── transfers/               # International wire transfers (Wise)
│   ├── cards/                   # Virtual cards
│   ├── funding/                 # Add funds (Stripe / Plaid)
│   ├── merchants/               # Merchant dashboard
│   ├── profile/                 # Profile, KYC, settings
│   └── security/                # 2FA setup, change password
└── shared/
    ├── providers/               # walletProvider, authProvider, etc.
    └── widgets/                 # Reusable UI components
```

---

## Project Structure — Backend API

```
src/
├── server.js           # HTTP server entry point (port 3000)
├── app.js              # Express app setup, all routes mounted
├── routes/             # 19 route files (one per feature)
├── services/           # Business logic (paymentService, walletService, etc.)
├── middleware/
│   ├── authenticate.js # JWT auth — use: const { authenticate } = require(...)
│   ├── rateLimiter.js  # Redis-backed rate limiting
│   └── fraudCheck.js   # Fraud heuristics
├── db/
│   ├── knex.js         # Database connection pool
│   ├── migrations/     # 10 migration files (run: npm run migrate)
│   ├── models/         # Query helpers per table
│   └── seeds/          # Test data (run: npm run seed)
└── utils/
    ├── ApiError.js     # Structured error class
    └── response.js     # success() response helper
```

---

## Live API Endpoints

Base URL: `https://amixpay-api-production.up.railway.app`

| Route | Description |
|---|---|
| `GET /health` | Health check (no auth required) |
| `POST /v1/auth/register` | Create account |
| `POST /v1/auth/login` | Login → returns JWT |
| `GET /v1/wallets` | Get wallet balances |
| `POST /v1/payments/send` | Send money to another user |
| `GET /v1/wallets/transactions` | Transaction history |
| `POST /v1/payment-requests` | Request money |
| `GET /v1/exchange-rates` | Live exchange rates |
| `POST /v1/transfers/quote` | International transfer quote |

All routes except `/health` and `/v1/auth/*` require:
```
Authorization: Bearer <jwt_token>
```

---

## Build APK / AAB

```bash
# APK (install directly on Android)
flutter build apk --release --dart-define=API_URL=https://amixpay-api-production.up.railway.app/v1

# AAB (upload to Google Play Store)
flutter build appbundle --release --dart-define=API_URL=https://amixpay-api-production.up.railway.app/v1
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## GitHub Repositories

| Repo | URL |
|---|---|
| Flutter App | https://github.com/AmizPay/amixpay-app |
| Backend API | https://github.com/AmizPay/amixpay-api |

---

## Test Accounts (for investor demo)

Register a new account at:
`POST https://amixpay-api-production.up.railway.app/v1/auth/register`

Or use the demo mode — the app automatically falls back to demo data if the server is unreachable.

---

## Key Technologies

| Technology | Version | Purpose |
|---|---|---|
| Flutter | 3.41.4 | Mobile UI framework |
| Dart | 3.x | Flutter language |
| Riverpod | ^2.x | State management |
| GoRouter | ^14.x | Navigation/routing |
| Dio | ^5.x | HTTP client |
| Node.js | 20 | Backend runtime |
| Express | ^5.x | API framework |
| PostgreSQL | 15 | Database |
| Knex.js | ^3.x | Query builder + migrations |
| Railway | — | Cloud hosting (API + DB) |
| Firebase | — | Push notifications + Crashlytics |
| Stripe | — | Card payments |
| Flutterwave | — | African payment rails |
