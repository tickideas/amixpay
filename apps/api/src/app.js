const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const requestId = require('./middleware/requestId');
const errorHandler = require('./middleware/errorHandler');
const { generalLimiter } = require('./middleware/rateLimiter');

// Route imports
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const walletRoutes = require('./routes/wallets');
const paymentRoutes = require('./routes/payments');
const paymentRequestRoutes = require('./routes/paymentRequests');
const qrRoutes = require('./routes/qr');
const transferRoutes = require('./routes/transfers');
const currencyRoutes = require('./routes/currencies');
const notificationRoutes = require('./routes/notifications');
const splitRoutes = require('./routes/splits');
const fundingRoutes = require('./routes/funding');
const merchantRoutes = require('./routes/merchants');
const virtualCardRoutes = require('./routes/virtualCards');
const stripeRoutes = require('./routes/stripe');
const adminFraudRoutes = require('./routes/adminFraud');
const exchangeRateRoutes = require('./routes/exchangeRates');
const zelleRoutes = require('./routes/zelle');
const bankingRoutes = require('./routes/banking');
const flutterwaveRoutes = require('./routes/flutterwave');
const savingsRoutes = require('./routes/savings');
const scheduledRoutes = require('./routes/scheduled');
const referralRoutes = require('./routes/referrals');

const isProduction = process.env.NODE_ENV === 'production';
const app = express();

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disabled for API
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// ── CORS: explicit origins in production, permissive in dev ──────────────────
const corsOrigin = (() => {
  if (process.env.ALLOWED_ORIGINS) {
    return process.env.ALLOWED_ORIGINS.split(',').map((s) => s.trim());
  }
  if (isProduction) {
    console.warn('[SECURITY] ALLOWED_ORIGINS not set in production — CORS will reject all cross-origin requests.');
    return false; // Reject all cross-origin requests
  }
  return true; // Reflect request origin in dev (equivalent to * but allows credentials)
})();

app.use(cors({
  origin: corsOrigin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
}));

// Stripe webhook needs raw body BEFORE express.json()
app.use('/v1/stripe/webhooks', express.raw({ type: 'application/json' }));

// General middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(isProduction ? 'combined' : 'dev'));
app.use(requestId);
app.use(generalLimiter);

// Health check (no auth)
app.get('/health', async (req, res) => {
  const db = require('./db/knex');
  let dbStatus = 'ok';
  try {
    await db.raw('SELECT 1');
  } catch (_) {
    dbStatus = 'unavailable';
  }
  res.json({
    status: 'ok',
    service: 'amixpay-api',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    db: dbStatus,
  });
});

// API v1 routes
app.use('/v1/auth', authRoutes);
app.use('/v1/users', userRoutes);
app.use('/v1/wallets', walletRoutes);
app.use('/v1/payments', paymentRoutes);
app.use('/v1/payment-requests', paymentRequestRoutes);
app.use('/v1/qr', qrRoutes);
app.use('/v1/transfers', transferRoutes);
app.use('/v1/currencies', currencyRoutes);
app.use('/v1/exchange-rates', exchangeRateRoutes);
app.use('/v1/notifications', notificationRoutes);
app.use('/v1/splits', splitRoutes);
app.use('/v1/funding', fundingRoutes);
app.use('/v1/merchants', merchantRoutes);
app.use('/v1/virtual-cards', virtualCardRoutes);
app.use('/v1/stripe', stripeRoutes);
app.use('/v1/admin/fraud', adminFraudRoutes);
app.use('/v1/zelle', zelleRoutes);
app.use('/v1/banking', bankingRoutes);
app.use('/v1/flutterwave', flutterwaveRoutes);
app.use('/v1/savings', savingsRoutes);
app.use('/v1/scheduled', scheduledRoutes);
app.use('/v1/referrals', referralRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: { code: 'NOT_FOUND', message: `Route ${req.method} ${req.path} not found` },
  });
});

// Global error handler
app.use(errorHandler);

module.exports = app;
