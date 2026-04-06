process.on('uncaughtException', (err) => console.error('[CRASH]', err.stack));
process.on('unhandledRejection', (r) => console.error('[REJECT]', r));

const express = require('express');
const port = process.env.PORT || 3000;

// Bind port FIRST so Railway sees it open within startup timeout
const bare = express();
bare.get('/health', (req, res) => res.json({ ok: true, port, status: 'starting' }));
bare.get('/ping',   (req, res) => res.json({ ok: true, port }));

const srv = bare.listen(port, '0.0.0.0', async () => {
  console.log('[AmixPay] PORT OPEN on', port);

  // Run DB migrations now that port is already bound
  try {
    const db = require('./db/knex');
    await db.migrate.latest();
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
  console.log('[AmixPay] Full app mounted — ready');
});

srv.on('error', (err) => { console.error('[AmixPay] bind error:', err.message); process.exit(1); });
