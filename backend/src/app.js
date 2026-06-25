const express = require('express');
const cors = require('cors');
require('dotenv').config();

const path = require('path');
const db = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const ticketRoutes = require('./routes/ticketRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Static files directory for uploads
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Middleware
app.use(cors());
app.use(express.json());

// API Request Logger Middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`📡 [${timestamp}] ${req.method} ${req.originalUrl}`);
  if (Object.keys(req.body).length > 0) {
    // Hide password during logs
    const bodyCopy = { ...req.body };
    if (bodyCopy.password) bodyCopy.password = '********';
    console.log('📦 Body:', bodyCopy);
  }
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/notifications', notificationRoutes);

// Root endpoint for status check
app.get('/', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'E-Ticketing Helpdesk REST API is running!',
    version: '1.0.0'
  });
});

// 404 Route handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    error: {
      message: 'Not Found',
      statusCode: 404,
      details: `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`
    }
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('❌ Server Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: 'Internal Server Error',
    error: {
      message: err.message || 'Internal Server Error',
      statusCode: err.status || 500,
      details: err.stack
    }
  });
});

// Initialize database then start server
const startServer = async () => {
  try {
    // Auto initialize PostgreSQL tables and seed data
    await db.initDb();
    
    app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
      console.log(`🔗 Local URL: http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();
