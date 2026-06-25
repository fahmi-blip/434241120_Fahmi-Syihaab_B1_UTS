const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticateJWT } = require('../middlewares/auth');

// All notification routes require authentication
router.use(authenticateJWT);

router.get('/', notificationController.getNotifications);
router.put('/:id/read', notificationController.markNotifRead);

module.exports = router;
