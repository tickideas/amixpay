const jwt = require('jsonwebtoken');
const ApiError = require('../utils/ApiError');
const User = require('../db/models/User');
const config = require('../config');
const { redisExists } = require('../redis/client');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Missing or invalid Authorization header');
    }

    const token = authHeader.slice(7);

    // Check token blacklist
    const blacklisted = await redisExists(`blacklist:${token}`);
    if (blacklisted) throw ApiError.unauthorized('Token has been revoked');

    let payload;
    try {
      payload = jwt.verify(token, config.jwt.secret);
    } catch (err) {
      if (err.name === 'TokenExpiredError') throw ApiError.unauthorized('Token expired');
      throw ApiError.unauthorized('Invalid token');
    }

    const user = await User.findById(payload.userId || payload.sub);
    if (!user) throw ApiError.unauthorized('User not found');
    if (user.status === 'suspended') throw ApiError.forbidden('Account suspended');
    if (user.status === 'closed') throw ApiError.forbidden('Account closed');

    req.user = user;
    req.token = token;
    next();
  } catch (err) {
    next(err);
  }
};

const requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return next(ApiError.forbidden('Admin access required'));
  }
  next();
};

const requireMerchant = (req, res, next) => {
  if (!req.user || !['merchant', 'admin'].includes(req.user.role)) {
    return next(ApiError.forbidden('Merchant access required'));
  }
  next();
};

module.exports = { authenticate, requireAdmin, requireMerchant };
