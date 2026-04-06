const users = new Map();
const emailIndex = new Map();

function create(userData) {
  users.set(userData.id, userData);
  emailIndex.set(userData.email.toLowerCase(), userData.id);
  return sanitize(userData);
}

function findById(id) {
  return users.get(id) || null;
}

function findByEmail(email) {
  const id = emailIndex.get(email.toLowerCase());
  if (!id) return null;
  return users.get(id) || null;
}

function update(id, partial) {
  const user = users.get(id);
  if (!user) return null;
  Object.assign(user, partial, { updated_at: new Date().toISOString() });
  return sanitize(user);
}

function exists(email) {
  return emailIndex.has(email.toLowerCase());
}

function sanitize(user) {
  const { password_hash, totp_secret, backup_codes, ...safe } = user;
  return safe;
}

module.exports = { create, findById, findByEmail, update, exists, sanitize };
