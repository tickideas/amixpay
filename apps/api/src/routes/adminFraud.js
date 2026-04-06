const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate, requireAdmin } = require('../middleware/authenticate');
const fraudService = require('../services/fraudService');
const kycService = require('../services/kycService');
const User = require('../db/models/User');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate, requireAdmin);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

// GET /v1/admin/fraud/alerts
router.get('/alerts',
  [
    query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
    query('offset').optional().isInt({ min: 0 }).toInt(),
    query('status').optional().isIn(['open', 'reviewed', 'blocked', 'dismissed']),
    query('severity').optional().isIn(['low', 'medium', 'high', 'critical']),
  ],
  validate,
  async (req, res, next) => {
    try {
      const alerts = await fraudService.listAlerts(req.query);
      success(res, alerts);
    } catch (err) { next(err); }
  }
);

// GET /v1/admin/fraud/alerts/:id
router.get('/alerts/:id', async (req, res, next) => {
  try {
    const alert = await fraudService.getAlert(req.params.id);
    if (!alert) return res.status(404).json({ success: false, error: { message: 'Alert not found' } });
    success(res, alert);
  } catch (err) { next(err); }
});

// PATCH /v1/admin/fraud/alerts/:id — Review alert
router.patch('/alerts/:id',
  [body('status').isIn(['reviewed', 'blocked', 'dismissed']), body('notes').optional().isString()],
  validate,
  async (req, res, next) => {
    try {
      const { status, notes } = req.body;
      const updated = await fraudService.reviewAlert(req.params.id, req.user.id, { status, notes });

      // If blocking, suspend the user
      if (status === 'blocked' && updated?.user_id) {
        await fraudService.blockUser(updated.user_id);
      }

      success(res, updated);
    } catch (err) { next(err); }
  }
);

// GET /v1/admin/fraud/rules (static for MVP)
router.get('/rules', (req, res) => {
  success(res, [
    { id: 'LARGE_AMOUNT', name: 'Large Amount', threshold: '$10,000', severity: 'high', active: true },
    { id: 'VELOCITY_5MIN', name: 'Velocity 5-min', threshold: '5 tx/5min', severity: 'medium', active: true },
    { id: 'VELOCITY_1HR', name: 'Velocity 1-hour', threshold: '20 tx/hr', severity: 'medium', active: true },
    { id: 'NEW_RECIPIENT', name: 'New Recipient', threshold: 'First transfer', severity: 'low', active: true },
  ]);
});

// GET /v1/admin/users — Admin user list
router.get('/users',
  [query('limit').optional().isInt({ min: 1, max: 100 }).toInt()],
  validate,
  async (req, res, next) => {
    try {
      const users = await User.list(req.query);
      success(res, users);
    } catch (err) { next(err); }
  }
);

// PATCH /v1/admin/kyc/:documentId — Approve or reject KYC document
router.patch('/kyc/:documentId',
  [body('action').isIn(['approve', 'reject']), body('reason').optional().isString()],
  validate,
  async (req, res, next) => {
    try {
      const { action, reason, level } = req.body;
      let result;
      if (action === 'approve') {
        result = await kycService.approveDocument(req.params.documentId, { level: parseInt(level || 1) });
      } else {
        result = await kycService.rejectDocument(req.params.documentId, reason || 'Does not meet requirements');
      }
      success(res, result);
    } catch (err) { next(err); }
  }
);

module.exports = router;
