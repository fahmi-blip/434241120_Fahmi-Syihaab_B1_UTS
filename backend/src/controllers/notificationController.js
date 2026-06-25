const db = require('../config/db');

// GET /api/notifications
const getNotifications = async (req, res) => {
  const userId = req.user.id;

  try {
    const notifQuery = await db.query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [userId]
    );

    return res.status(200).json(notifQuery.rows); // Flutter expects a direct List of notifications
  } catch (error) {
    console.error('Get Notifications Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

// PUT /api/notifications/:id/read
const markNotifRead = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    await db.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (error) {
    console.error('Mark Notification Read Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal Server Error',
      error: {
        message: 'Internal Server Error',
        statusCode: 500,
        details: error.message
      }
    });
  }
};

module.exports = {
  getNotifications,
  markNotifRead,
};
