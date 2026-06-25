const jwt = require('jsonwebtoken');
const db = require('../config/db');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkeyforeticketinghelpdesk123!';

const authenticateJWT = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
      error: {
        message: 'Token authentication required',
        statusCode: 401,
        details: 'Missing or malformed Authorization Bearer header'
      }
    });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Fetch profile from db to verify the user exists and get their latest role
    const userQuery = await db.query(
      'SELECT id, name, email, role, department, avatar FROM profiles WHERE id = $1',
      [decoded.userId]
    );

    if (userQuery.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized',
        error: {
          message: 'Unauthorized',
          statusCode: 401,
          details: 'User profile no longer exists'
        }
      });
    }

    // Attach user profile to request
    req.user = userQuery.rows[0];
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Unauthorized',
      error: {
        message: 'Unauthorized',
        statusCode: 401,
        details: 'Token expired atau invalid'
      }
    });
  }
};

const requireRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized',
        error: {
          message: 'Unauthorized',
          statusCode: 401,
          details: 'User details not loaded'
        }
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Forbidden',
        error: {
          message: 'Forbidden',
          statusCode: 403,
          details: 'Anda tidak punya akses ke resource ini'
        }
      });
    }

    next();
  };
};

module.exports = {
  authenticateJWT,
  requireRole,
  JWT_SECRET,
};
