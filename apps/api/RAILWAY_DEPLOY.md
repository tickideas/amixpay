# AmixPay API — Railway Deployment Guide

## 1. One-time Setup (15 minutes)

### Step 1 — Create Railway project
1. Go to https://railway.app → New Project → Deploy from GitHub repo
2. Select the `velocash-api` repo (or upload folder)
3. Railway auto-detects Node.js from `package.json`

### Step 2 — Add PostgreSQL
1. In your Railway project → **+ New** → **Database** → **PostgreSQL**
2. Railway auto-injects `DATABASE_URL` — the app reads individual `DB_*` vars, so also set:
   - `DB_HOST` = from Railway PostgreSQL → Connect tab → Host
   - `DB_PORT` = `5432`
   - `DB_NAME` = from Railway → Database name
   - `DB_USER` = from Railway → Username
   - `DB_PASSWORD` = from Railway → Password

### Step 3 — Add Redis
1. **+ New** → **Database** → **Redis**
2. Railway injects `REDIS_URL` — set it explicitly too:
   - `REDIS_URL` = from Railway Redis → Connect tab → copy the full URL

### Step 4 — Set Environment Variables
Go to your API service → **Variables** tab → add all of these:

```
# Core
PORT=3000
NODE_ENV=production
JWT_SECRET=<generate: openssl rand -hex 64>
JWT_REFRESH_SECRET=<generate: openssl rand -hex 64>

# Database (from Step 2)
DB_HOST=
DB_PORT=5432
DB_NAME=
DB_USER=
DB_PASSWORD=

# Redis (from Step 3)
REDIS_URL=

# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Flutterwave
FLW_PUBLIC_KEY=FLWPUBK-...
FLW_SECRET_KEY=FLWSECK-...
FLW_ENCRYPTION_KEY=...
FLW_WEBHOOK_HASH=<set this in Flutterwave dashboard → Webhooks → Secret Hash>
FLW_CALLBACK_URL=https://<your-railway-domain>/v1/flutterwave/webhooks

# Wise (international transfers)
WISE_API_KEY=
WISE_PROFILE_ID=
WISE_API_URL=https://api.transferwise.com
WISE_ENV=live

# Plaid (bank linking)
PLAID_CLIENT_ID=69b83d3f9b9597000d2afebb
PLAID_SECRET=<production secret from Plaid dashboard>
PLAID_ENV=production

# Open Exchange Rates (live FX)
OXR_APP_ID=bda60ab884f4457882e56600f8834315

# Firebase (push notifications)
FIREBASE_PROJECT_ID=amixpay-6625d
FIREBASE_SERVER_KEY=<from Firebase Console → Project Settings → Cloud Messaging>

# Twilio SMS (optional)
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# SendGrid email (optional)
SENDGRID_API_KEY=
SENDGRID_FROM_EMAIL=noreply@amixpay.com
```

### Step 5 — Deploy
Railway auto-deploys on every push. First deploy runs:
```
npx knex migrate:latest --knexfile knexfile.js && node src/server.js
```
Migrations run automatically before the server starts.

### Step 6 — Get your live URL
Railway gives you a URL like: `https://amixpay-api-production.up.railway.app`

Test it:
```bash
curl https://amixpay-api-production.up.railway.app/health
# → {"ok":true,"db":"connected","uptime":...}
```

### Step 7 — Update Flutter app API base URL
In your Flutter app, update the API base URL:
```dart
// lib/core/network/dio_client.dart
const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://amixpay-api-production.up.railway.app/v1',
);
```

Build with:
```bash
flutter build apk --release \
  --dart-define=API_URL=https://amixpay-api-production.up.railway.app/v1 \
  --dart-define=FLW_PUBLIC_KEY=FLWPUBK-...
```

---

## Pricing
- **Hobby plan**: $5/month (500 hours compute + PostgreSQL + Redis included)
- **Free trial**: $5 credit on signup — enough for first deployment test

## Custom Domain
Railway project → Settings → Domains → Add custom domain → `api.amixpay.com`
Point your DNS CNAME to the Railway domain.
