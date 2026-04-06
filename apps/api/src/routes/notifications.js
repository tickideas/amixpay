const { Router } = require('express');
const { body, query, validationResult } = require('express-validator');
const { authenticate } = require('../middleware/authenticate');
const notificationService = require('../services/notificationService');
const { success } = require('../utils/response');

const router = Router();
router.use(authenticate);

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR', details: errors.array() } });
  next();
};

router.get('/',
  [query('limit').optional().isInt({ min: 1, max: 100 }).toInt(), query('offset').optional().isInt({ min: 0 }).toInt()],
  validate,
  async (req, res, next) => {
    try {
      const items = await notificationService.list(req.user.id, req.query);
      const unread = await notificationService.countUnread(req.user.id);
      success(res, { items, unreadCount: unread });
    } catch (err) { next(err); }
  }
);

router.patch('/:id/read', async (req, res, next) => {
  try {
    const notif = await notificationService.markRead(req.params.id, req.user.id);
    success(res, notif);
  } catch (err) { next(err); }
});

router.post('/read-all', async (req, res, next) => {
  try {
    await notificationService.markAllRead(req.user.id);
    success(res, { message: 'All notifications marked as read' });
  } catch (err) { next(err); }
});

router.get('/settings', async (req, res, next) => {
  try {
    const prefs = await notificationService.getPreferences(req.user.id);
    success(res, prefs || { push_enabled: true, sms_enabled: true, email_enabled: true });
  } catch (err) { next(err); }
});

router.put('/settings', async (req, res, next) => {
  try {
    const prefs = await notificationService.updatePreferences(req.user.id, req.body);
    success(res, prefs);
  } catch (err) { next(err); }
});

router.post('/devices',
  [body('deviceToken').notEmpty(), body('platform').isIn(['ios', 'android', 'web'])],
  validate,
  async (req, res, next) => {
    try {
      const device = await notificationService.registerDevice(req.user.id, req.body);
      res.status(201).json({ success: true, data: device });
    } catch (err) { next(err); }
  }
);

module.exports = router;
