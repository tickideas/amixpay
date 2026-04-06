const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const User = require('../db/models/User');
const kycService = require('../services/kycService');
const { success } = require('../utils/response');
const ApiError = require('../utils/ApiError');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// GET /v1/users/me
router.get('/me', async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    success(res, User.safeFields(user));
  } catch (err) { next(err); }
});

// PATCH /v1/users/me
router.patch('/me',
  [
    body('firstName').optional().trim().notEmpty(),
    body('lastName').optional().trim().notEmpty(),
    body('phone').optional().isMobilePhone(),
    body('dateOfBirth').optional().isDate(),
    body('countryCode').optional().isLength({ min: 2, max: 3 }),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { firstName, lastName, phone, dateOfBirth, countryCode } = req.body;
      const updated = await User.update(req.user.id, {
        ...(firstName && { first_name: firstName }),
        ...(lastName && { last_name: lastName }),
        ...(phone && { phone }),
        ...(dateOfBirth && { date_of_birth: dateOfBirth }),
        ...(countryCode && { country_code: countryCode }),
      });
      success(res, User.safeFields(updated));
    } catch (err) { next(err); }
  }
);

// PUT /v1/users/me/avatar
router.put('/me/avatar',
  [body('avatarUrl').isURL()],
  validate,
  async (req, res, next) => {
    try {
      const updated = await User.update(req.user.id, { avatar_url: req.body.avatarUrl });
      success(res, { avatarUrl: updated.avatar_url });
    } catch (err) { next(err); }
  }
);

// GET /v1/users/lookup?q=username/email/phone
router.get('/lookup',
  [query('q').notEmpty().withMessage('Search query required')],
  validate,
  async (req, res, next) => {
    try {
      const user = await User.findByIdentifier(req.query.q);
      if (!user) return next(ApiError.notFound('User not found'));
      // Return only public fields
      success(res, {
        id: user.id,
        username: user.username,
        firstName: user.first_name,
        lastName: user.last_name,
        avatarUrl: user.avatar_url,
      });
    } catch (err) { next(err); }
  }
);

// POST /v1/users/me/kyc
router.post('/me/kyc',
  [body('type').notEmpty(), body('s3Key').notEmpty()],
  validate,
  async (req, res, next) => {
    try {
      const doc = await kycService.submitDocument(req.user.id, { type: req.body.type, s3Key: req.body.s3Key });
      res.status(201).json({ success: true, data: doc });
    } catch (err) { next(err); }
  }
);

// GET /v1/users/me/kyc/status
router.get('/me/kyc/status', async (req, res, next) => {
  try {
    const status = await kycService.getStatus(req.user.id);
    success(res, status);
  } catch (err) { next(err); }
});

module.exports = router;
