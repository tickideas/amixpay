require('dotenv').config();

// ── Security: JWT_SECRET is mandatory in production ──────────────────────────
const isProduction = (process.env.NODE_ENV || 'development') === 'production';

if (!process.env.JWT_SECRET && isProduction) {
  console.error('[FATAL] JWT_SECRET environment variable is required in production.');
  console.error('Generate one with: node -e "console.log(require(\'crypto\').randomBytes(64).toString(\'hex\'))"');
  process.exit(1);
}

if (!process.env.JWT_SECRET) {
  console.warn('[WARN] JWT_SECRET not set — using dev-only fallback. NEVER run production without it.');
}

module.exports = {
  port: parseInt(process.env.PORT, 10) || 3000,
  env: process.env.NODE_ENV || 'development',

  jwt: {
    secret: process.env.JWT_SECRET || (isProduction ? undefined : 'dev_secret_DO_NOT_USE_IN_PROD'),
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRY || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRY || '30d',
  },

  db: {
    url: process.env.DATABASE_URL,
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT, 10) || 5432,
    name: process.env.DB_NAME || 'amixpay',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
  },

  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  },

  email: {
    sendgridKey: process.env.SENDGRID_API_KEY || '',
    from: process.env.SENDGRID_FROM_EMAIL || 'noreply@amixpay.com',
    smtpHost: process.env.SMTP_HOST || '',
    smtpPort: parseInt(process.env.SMTP_PORT, 10) || 587,
    smtpUser: process.env.SMTP_USER || '',
    smtpPass: process.env.SMTP_PASS || '',
  },

  appUrl: process.env.APP_URL || 'https://api.amixpay.com',
  frontendUrl: process.env.FRONTEND_URL || 'amixpay://reset-password',

  stripe: {
    secretKey: process.env.STRIPE_SECRET_KEY || '',
    webhookSecret: process.env.STRIPE_WEBHOOK_SECRET || '',
  },
};
