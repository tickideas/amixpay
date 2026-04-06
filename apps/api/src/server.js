process.on('uncaughtException', (err) => console.error('[CRASH]', err.stack));
process.on('unhandledRejection', (r) => console.error('[REJECT]', r));

const express = require('express');
const port = process.env.PORT || 3000;

let dbOk = false;
let appMounted = false;

// Bind port FIRST so the container reports healthy quickly
const bare = express();

bare.get('/health', async (req, res) => {
  // Quick DB connectivity check
  let dbStatus = dbOk ? 'connected' : 'not connected';
  if (appMounted) {
    try {
      const db = require('./db/knex');
      await db.raw('SELECT 1');
      dbStatus = 'connected';
      dbOk = true;
    } catch (e) {
      dbStatus = `error: ${e.message}`;
      dbOk = false;
    }
  }

  res.json({
    ok: dbOk && appMounted,
    port,
    status: appMounted ? 'ready' : 'starting',
    db: dbStatus,
    env: {
      NODE_ENV: process.env.NODE_ENV || 'not set',
      DB_HOST: process.env.DB_HOST || 'not set',
      DB_PASSWORD: process.env.DB_PASSWORD ? '***set***' : 'MISSING',
      JWT_SECRET: process.env.JWT_SECRET ? '***set***' : 'MISSING',
      REDIS_URL: process.env.REDIS_URL ? '***set***' : 'not set',
      ALLOWED_ORIGINS: process.env.ALLOWED_ORIGINS || 'not set',
    },
  });
});

bare.get('/ping', (req, res) => res.json({ ok: true, port }));

const srv = bare.listen(port, '0.0.0.0', async () => {
  console.log('[AmixPay] PORT OPEN on', port);

  // Run DB migrations now that port is already bound
  try {
    const db = require('./db/knex');
    await db.migrate.latest();
    dbOk = true;
    console.log('[AmixPay] Migrations: up to date');
  } catch (err) {
    console.error('[AmixPay] Migration error (continuing):', err.message);
  }

  // Load and mount the full app
  let fullApp;
  try {
    fullApp = require('./app');
    console.log('[AmixPay] app.js loaded OK');
  } catch (err) {
    console.error('[AmixPay] app.js LOAD FAILED:', err.message, err.stack);
    return; // /health still alive so logs are visible
  }

  srv.removeAllListeners('request');
  srv.on('request', fullApp);
  appMounted = true;
  console.log('[AmixPay] Full app mounted — ready');
});

srv.on('error', (err) => { console.error('[AmixPay] bind error:', err.message); process.exit(1); });
