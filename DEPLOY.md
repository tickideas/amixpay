# AmixPay — Dokploy Deployment Guide

## Overview

The API deploys as a **Docker Compose** stack on Dokploy with three services:

| Service | Image | Purpose |
|---|---|---|
| `api` | Built from `apps/api/Dockerfile` | Node.js Express API |
| `postgres` | `postgres:15-alpine` | PostgreSQL database |
| `redis` | `redis:7-alpine` | Rate limiting, session cache |

Dokploy pulls from the GitHub repo, builds the API image, and runs the compose stack. Postgres and Redis are internal (no ports exposed to the internet). Dokploy's Traefik handles SSL termination and routing.

---

## Step-by-Step Setup

### 1. Create a Compose Project in Dokploy

1. Go to Dokploy dashboard → **Projects** → **Create Project**
2. Name it `amixpay` (or whatever you prefer)
3. Inside the project, click **Create Service** → **Compose**
4. **Source**: GitHub
5. **Repository**: `tickideas/amixpay`
6. **Branch**: `main`
7. **Compose Path**: `docker-compose.prod.yml`

### 2. Set Environment Variables

In Dokploy → your compose service → **Environment**:

**Required (app will crash without these):**

```env
# Generate with: openssl rand -hex 64
JWT_SECRET=<paste-your-64-byte-hex-secret>

# Strong random password for the database
POSTGRES_PASSWORD=<generate-a-strong-password>
```

**Recommended:**

```env
# Your API domain
APP_URL=https://api.yourdomain.com

# Comma-separated origins allowed for CORS
# Leave empty to block all cross-origin in production
ALLOWED_ORIGINS=https://yourdomain.com

# Stripe (if accepting card payments)
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email (for password resets, receipts)
SENDGRID_API_KEY=SG....
SENDGRID_FROM_EMAIL=noreply@yourdomain.com

# SMS OTP (for phone verification)
TWILIO_ACCOUNT_SID=AC...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=+1...

# Exchange rates (for live currency conversion)
OPEN_EXCHANGE_RATES_KEY=...
```

**Optional:**

```env
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=30d
FLW_PUBLIC_KEY=...
FLW_SECRET_KEY=...
FLW_ENCRYPTION_KEY=...
FIREBASE_SERVER_KEY=...
```

See `apps/api/.env.example` for the full list.

### 3. Configure Domain

1. In Dokploy → your compose service → **Domains**
2. Add your domain (e.g. `api.yourdomain.com`)
3. **Service Name**: `api` (this tells Traefik to route to the API container)
4. **Container Port**: `3000`
5. Enable **HTTPS** (Dokploy handles Let's Encrypt automatically)

### 4. Deploy

Click **Deploy** in Dokploy. It will:
1. Pull the repo from GitHub
2. Build the API Docker image (multi-stage, ~150MB)
3. Start Postgres → Redis → API (in order, with health checks)
4. API runs migrations automatically on startup (`server.js` calls `db.migrate.latest()`)
5. Traefik routes `api.yourdomain.com` → container port 3000

### 5. Verify

```bash
# Health check
curl https://api.yourdomain.com/health
# → {"ok":true,"port":3000,"status":"starting"}  (then "ready" after app mounts)

# Ping
curl https://api.yourdomain.com/ping
# → {"ok":true,"port":3000}

# Full app mounted?
curl https://api.yourdomain.com/v1/auth/register -X POST -H "Content-Type: application/json" -d '{}'
# → 400 error with validation messages (means the app is running)
```

---

## Auto-Deploy on Push

In Dokploy → your compose service → **General**:
- Enable **Autodeploy** to rebuild on every push to `main`

This pairs with the GitHub Actions CI — tests run first, then Dokploy deploys if the push lands on `main`.

---

## Database Backups

Postgres data lives in a Docker volume (`postgres_data`). Set up backups:

**Option A: Dokploy's built-in backups** (if available in your version)

**Option B: Cron job on the host**

```bash
# Add to crontab on your Dokploy server
# Daily backup at 2am, keep 7 days
0 2 * * * docker exec amixpay-postgres pg_dump -U postgres amixpay | gzip > /backups/amixpay-$(date +\%Y\%m\%d).sql.gz
0 3 * * * find /backups -name "amixpay-*.sql.gz" -mtime +7 -delete
```

**Option C: Stream to S3**

```bash
0 2 * * * docker exec amixpay-postgres pg_dump -U postgres amixpay | gzip | aws s3 cp - s3://your-bucket/backups/amixpay-$(date +%Y%m%d).sql.gz
```

---

## Scaling Notes

The current setup runs everything on one server. If you need to scale:

- **API**: increase container replicas in the compose file (remove `container_name` first)
- **Postgres**: move to a managed DB (Supabase, Neon, RDS) and set `DATABASE_URL` + `DB_SSL=true`
- **Redis**: move to managed Redis (Upstash, ElastiCache) and update `REDIS_URL`

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| API crashes on startup | Check `JWT_SECRET` is set. Check Dokploy logs for `[FATAL]` messages |
| "CORS blocked" in mobile app | Add the app's origin to `ALLOWED_ORIGINS` |
| Migration errors | Check Dokploy logs for `[AmixPay] Migration error`. Usually a missing column or table conflict |
| "Connection refused" to Postgres | Postgres isn't healthy yet. Check `docker logs amixpay-postgres` |
| Redis connection error | Non-fatal — API falls back to in-memory rate limiting. But check `docker logs amixpay-redis` |
| SSL cert not working | Dokploy/Traefik needs port 80+443 open. Check your firewall |

---

## ⚠️ Critical Dokploy Compose Rules

These were learned the hard way. **Do not deviate from these patterns** or Dokploy routing will silently break.

### 1. Never define custom Docker networks

```yaml
# ❌ WRONG — isolates containers from Dokploy's Traefik proxy
networks:
  my-net:
    driver: bridge

services:
  api:
    networks:
      - my-net
```

```yaml
# ✅ CORRECT — let Dokploy manage networks
services:
  api:
    # no networks key
```

Dokploy's Traefik runs on its own internal network (`dokploy-network`). If you define a custom bridge network, your containers are isolated from Traefik and **domain routing silently fails** — traffic falls through to another app or returns Traefik's default cert.

### 2. Never set `container_name`

```yaml
# ❌ WRONG — conflicts with Dokploy's naming
container_name: amixpay-api
```

```yaml
# ✅ CORRECT — Dokploy manages container names
services:
  api:
    # no container_name key
```

Dokploy generates unique container names. Hardcoding them causes conflicts on redeploy and breaks Dokploy's internal tracking.

### 3. Never add Traefik labels manually

```yaml
# ❌ WRONG — conflicts with Dokploy's auto-generated Traefik config
labels:
  - "traefik.enable=true"
```

Dokploy generates all Traefik labels from the **Domains** UI. Manual labels conflict with or override Dokploy's routing rules.

### 4. Use unique service names when running multiple stacks

If you have multiple compose stacks on the same Dokploy server (e.g. `amixpay` + `echurcher`), avoid generic service names like `postgres` or `redis` that can collide via Docker DNS:

```yaml
# ✅ Namespaced to avoid cross-stack DNS collisions
services:
  amixpay-postgres:
    image: postgres:15-alpine
  amixpay-redis:
    image: redis:7-alpine
  api:
    environment:
      DB_HOST: amixpay-postgres
      REDIS_URL: redis://amixpay-redis:6379
```

### 5. Use `127.0.0.1` not `localhost` in healthchecks

Alpine-based images may resolve `localhost` to IPv6 (`::1`), but Node.js listens on IPv4 (`0.0.0.0`). This causes healthchecks to fail silently:

```dockerfile
# ❌ WRONG — may resolve to ::1 on Alpine
HEALTHCHECK CMD wget -qO- http://localhost:3000/health || exit 1

# ✅ CORRECT — explicit IPv4
HEALTHCHECK CMD wget -qO- http://127.0.0.1:3000/health || exit 1
```

### 6. Postgres password is set at volume init only

`POSTGRES_PASSWORD` is only used when the Postgres data volume is first created. Changing the env var later does **not** update the stored password. If you get `password authentication failed`:

- **Option A (keep data):** `ALTER USER postgres WITH PASSWORD 'new_password';` inside the postgres container
- **Option B (fresh start):** Delete the `postgres_data` volume and redeploy

### Summary: minimal working Dokploy compose pattern

```yaml
name: myapp

services:
  api:
    build: .
    restart: unless-stopped
    depends_on:
      myapp-db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://user:${DB_PASSWORD}@myapp-db:5432/myapp

  myapp-db:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

No custom networks. No container names. No Traefik labels. Let Dokploy handle routing.

---

## Migration from Railway

If you're moving an existing Railway deployment:

1. **Export the database**: `pg_dump` from Railway's Postgres → import into Dokploy's Postgres
2. **Copy env vars**: Railway dashboard → Dokploy environment tab
3. **Update Flutter app**: change `API_BASE_URL` to your new Dokploy domain
4. **Update Stripe webhooks**: point to new domain in Stripe dashboard
5. **DNS**: update A/CNAME record to point to your Dokploy server IP
