#!/bin/sh
set -e
echo "[AmixPay] Running migrations..."
npx knex migrate:latest --knexfile knexfile.js
echo "[AmixPay] Running seeds..."
npx knex seed:run --knexfile knexfile.js
echo "[AmixPay] Database initialized!"
