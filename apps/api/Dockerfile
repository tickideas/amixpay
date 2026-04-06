# ── Stage 1: Install dependencies ─────────────────────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev && npm cache clean --force

# ── Stage 2: Production image ────────────────────────────────────────────────
FROM node:20-alpine

# Security: run as non-root
RUN addgroup -S amixpay && adduser -S amixpay -G amixpay

WORKDIR /app

# Copy dependencies from build stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application code
COPY package.json knexfile.js ./
COPY src/ ./src/

# Own everything by the app user
RUN chown -R amixpay:amixpay /app

USER amixpay

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1

CMD ["node", "src/server.js"]
