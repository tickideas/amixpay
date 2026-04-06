const { createClient } = require('redis');

// In-memory fallback store when Redis is unavailable
const memStore = new Map();
const memExpiry = new Map();

const memFallback = {
  isOpen: true,
  get: async (key) => {
    const exp = memExpiry.get(key);
    if (exp && Date.now() > exp) { memStore.delete(key); memExpiry.delete(key); return null; }
    return memStore.get(key) ?? null;
  },
  set: async (key, value) => { memStore.set(key, String(value)); return 'OK'; },
  setEx: async (key, ttl, value) => {
    memStore.set(key, String(value));
    memExpiry.set(key, Date.now() + ttl * 1000);
    return 'OK';
  },
  del: async (key) => { const had = memStore.has(key); memStore.delete(key); memExpiry.delete(key); return had ? 1 : 0; },
  incr: async (key) => { const v = parseInt(memStore.get(key) || '0') + 1; memStore.set(key, String(v)); return v; },
  expire: async (key, ttl) => { if (!memStore.has(key)) return 0; memExpiry.set(key, Date.now() + ttl * 1000); return 1; },
  exists: async (key) => memStore.has(key) ? 1 : 0,
};

let client = null;
let useMemFallback = false;

const getClient = async () => {
  if (useMemFallback) return memFallback;
  if (client && client.isOpen) return client;

  try {
    client = createClient({
      url: process.env.REDIS_URL || 'redis://localhost:6379',
      socket: { reconnectStrategy: false, connectTimeout: 2000 },
    });

    client.on('error', () => {}); // suppress noisy errors

    await Promise.race([
      client.connect(),
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 2000)),
    ]);

    client.on('error', (err) => console.error('[Redis] Error:', err.message));
    console.log('[Redis] Connected');
    return client;
  } catch {
    console.log('[Redis] Unavailable — using in-memory fallback');
    useMemFallback = true;
    client = null;
    return memFallback;
  }
};

// Convenience helpers
const redisGet = async (key) => { const c = await getClient(); return c.get(key); };
const redisSet = async (key, value, ttlSeconds) => {
  const c = await getClient();
  if (ttlSeconds) return c.setEx(key, ttlSeconds, String(value));
  return c.set(key, String(value));
};
const redisDel = async (key) => { const c = await getClient(); return c.del(key); };
const redisIncr = async (key) => { const c = await getClient(); return c.incr(key); };
const redisExpire = async (key, ttl) => { const c = await getClient(); return c.expire(key, ttl); };
const redisExists = async (key) => { const c = await getClient(); return c.exists(key); };

module.exports = { getClient, redisGet, redisSet, redisDel, redisIncr, redisExpire, redisExists };
