const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateJWT } = require('../middlewares/auth');

// Public routes
router.post('/login', authController.login);
router.post('/register', authController.register);
router.post('/reset-password', authController.resetPassword);

// Protected routes (require valid JWT)
router.post('/logout', authenticateJWT, authController.logout);
router.get('/me', authenticateJWT, authController.me);
router.put('/profile', authenticateJWT, authController.updateProfile);
router.get('/helpdesk', authenticateJWT, authController.getHelpdeskList);

// Additional endpoint for sanity check
router.get('/check', authenticateJWT, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Token is valid',
    data: {
      userId: req.user.id,
      role: req.user.role,
    }
  });
});

module.exports = router;
