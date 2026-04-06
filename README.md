# AmixPay

> Global digital wallet & money transfer platform.

## Monorepo Structure

```
amixpay/
├── apps/
│   ├── api/            ← Node.js / Express API (PostgreSQL, Redis)
│   └── mobile/         ← Flutter mobile app (iOS & Android)
├── packages/
│   └── api-contract/   ← Shared API contract & types (coming soon)
├── .github/
│   └── workflows/      ← CI/CD pipelines
├── docker-compose.yml  ← Full local dev environment
└── README.md
```

## Quick Start

### Prerequisites

- **Node.js** ≥ 18
- **Flutter** ≥ 3.11
- **Docker** & **Docker Compose** (for local Postgres + Redis)

### 1. Start infrastructure + API

```bash
# Copy env template
cp apps/api/.env.example apps/api/.env
# Edit apps/api/.env with your keys

# Start Postgres, Redis, run migrations, and launch API
docker compose up -d

# Or run API directly (requires local Postgres + Redis)
cd apps/api
npm install
npm run migrate
npm run dev
```

API is available at `http://localhost:3000`. Health check: `GET /health`.

### 2. Run the mobile app

```bash
cd apps/mobile
flutter pub get
flutter run
```

For Android emulator connecting to local API, the default `10.0.2.2:3000` works automatically.

For a physical device or custom API URL:

```bash
flutter run --dart-define=API_URL=http://YOUR_IP:3000/v1
```

## API Endpoints

All routes are under `/v1/`:

| Module | Prefix | Description |
|---|---|---|
| Auth | `/v1/auth` | Register, login, 2FA, password reset |
| Users | `/v1/users` | Profile, KYC |
| Wallets | `/v1/wallets` | Multi-currency wallets, transactions |
| Payments | `/v1/payments` | P2P send/receive |
| Transfers | `/v1/transfers` | International transfers (Wise) |
| QR | `/v1/qr` | QR code payments |
| Stripe | `/v1/stripe` | Card payments, virtual cards |
| Flutterwave | `/v1/flutterwave` | Mobile money (Africa) |
| Banking | `/v1/banking` | Bank connections (Plaid) |

See `apps/mobile/API_DOCS.md` for full endpoint documentation.

## Deployment

- **API**: Railway (nixpacks) — see `apps/api/railway.toml`
- **Mobile**: Manual APK/AAB builds — see `apps/mobile/DEPLOYMENT.md`

## License

Proprietary — All rights reserved.
