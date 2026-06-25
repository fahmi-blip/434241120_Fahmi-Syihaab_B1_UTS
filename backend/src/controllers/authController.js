const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/db');
const { JWT_SECRET } = require('../middlewares/auth');

// POST /api/auth/login
const login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Bad Request',
      error: {
        message: 'Bad Request',
        statusCode: 400,
        details: 'Email and password are required'
      }
    });
  }

  try {
    const userQuery = await db.query(
      'SELECT * FROM profiles WHERE email = $1',
      [email.toLowerCase().trim()]
    );

    if (userQuery.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized',
        error: {
          message: 'Unauthorized',
          statusCode: 401,
          details: 'Email atau password salah'
        }
      });
    }

    const user = userQuery.rows[0];
    const isMatch = bcrypt.compareSync(password, user.password_hash);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized',
        error: {
          message: 'Unauthorized',
          statusCode: 401,
          details: 'Email atau password salah'
        }
      });
    }

    // Generate token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '24h' } // 24 hours expiry
    );

    // Remove password hash from response
    delete user.password_hash;

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          department: user.department,
          role: user.role,
          avatar: user.avatar,
          created_at: user.created_at
        }
      }
    });
  } catch (error) {
    console.error('Login Error:', error);
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

// POST /api/auth/register
const register = async (req, res) => {
  const { name, email, password, phone, department, role } = req.body;

  if (!name || !email || !password) {
    return res.status(422).json({
      success: false,
      message: 'Unprocessable Entity',
      error: {
        message: 'Unprocessable Entity',
        statusCode: 422,
        details: 'Name, email, and password are required'
      }
    });
  }

  try {
    const trimmedEmail = email.toLowerCase().trim();
    // Check if email already registered
    const userExist = await db.query(
      'SELECT id FROM profiles WHERE email = $1',
      [trimmedEmail]
    );

    if (userExist.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Bad Request',
        error: {
          message: 'Bad Request',
          statusCode: 400,
          details: 'Email sudah terdaftar'
        }
      });
    }

    const id = uuidv4();
    const hashedPassword = bcrypt.hashSync(password, 10);
    const userRole = role || 'user'; // default role
    const defaultAvatar = `https://api.dicebear.com/7.x/adventurer/svg?seed=${encodeURIComponent(name)}`;

    const newUserQuery = await db.query(
      `INSERT INTO profiles (id, name, email, phone, department, role, avatar, password_hash)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, name, email, phone, department, role, avatar, created_at`,
      [id, name, trimmedEmail, phone || '', department || '', userRole, defaultAvatar, hashedPassword]
    );

    const newUser = newUserQuery.rows[0];

    return res.status(201).json({
      success: true,
      message: 'Registration successful. Please verify your email.',
      data: {
        user: newUser
      }
    });
  } catch (error) {
    console.error('Registration Error:', error);
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

// POST /api/auth/logout
const logout = (req, res) => {
  return res.status(200).json({
    success: true,
    message: 'Logout successful',
    data: {
      message: 'Logout successful',
      timestamp: new Date().toISOString()
    }
  });
};

// POST /api/auth/reset-password
const resetPassword = async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({
      success: false,
      message: 'Bad Request',
      error: {
        message: 'Bad Request',
        statusCode: 400,
        details: 'Email is required'
      }
    });
  }

  try {
    const userQuery = await db.query(
      'SELECT id FROM profiles WHERE email = $1',
      [email.toLowerCase().trim()]
    );

    if (userQuery.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Not Found',
        error: {
          message: 'Not Found',
          statusCode: 404,
          details: 'Email tidak ditemukan'
        }
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Password reset email sent',
      data: {
        message: 'Check your email for reset link'
      }
    });
  } catch (error) {
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

// GET /api/auth/me
const me = (req, res) => {
  return res.status(200).json({
    success: true,
    message: 'User retrieved successfully',
    data: req.user
  });
};

// PUT /api/auth/profile
const updateProfile = async (req, res) => {
  const { name, phone, department, avatar } = req.body;
  const userId = req.user.id;

  try {
    // Build update query dynamically
    const updates = [];
    const values = [];
    let paramIndex = 1;

    if (name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      values.push(name);
    }
    if (phone !== undefined) {
      updates.push(`phone = $${paramIndex++}`);
      values.push(phone);
    }
    if (department !== undefined) {
      updates.push(`department = $${paramIndex++}`);
      values.push(department);
    }
    if (avatar !== undefined) {
      updates.push(`avatar = $${paramIndex++}`);
      values.push(avatar);
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Bad Request',
        error: {
          message: 'Bad Request',
          statusCode: 400,
          details: 'No fields to update'
        }
      });
    }

    values.push(userId);
    const queryText = `
      UPDATE profiles 
      SET ${updates.join(', ')} 
      WHERE id = $${paramIndex} 
      RETURNING id, name, email, phone, department, role, avatar, created_at`;

    const updateQuery = await db.query(queryText, values);

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: updateQuery.rows[0]
    });
  } catch (error) {
    console.error('Update Profile Error:', error);
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

// GET /api/auth/helpdesk
const getHelpdeskList = async (req, res) => {
  try {
    const listQuery = await db.query(
      "SELECT id, name, email FROM profiles WHERE role IN ('admin', 'support', 'helpdesk') ORDER BY name ASC"
    );
    return res.status(200).json({
      success: true,
      message: 'Helpdesk staff retrieved successfully',
      data: listQuery.rows
    });
  } catch (error) {
    console.error('Get Helpdesk List Error:', error);
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
  login,
  register,
  logout,
  resetPassword,
  me,
  updateProfile,
  getHelpdeskList,
};
