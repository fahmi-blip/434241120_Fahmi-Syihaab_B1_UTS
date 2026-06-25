const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'eticketing_db',
  password: process.env.DB_PASSWORD || 'postgres',
  port: parseInt(process.env.DB_PORT || '5432'),
});

const query = (text, params) => pool.query(text, params);

const initDb = async () => {
  try {
    console.log('🔄 Connecting to PostgreSQL database...');
    // Test database connection
    await pool.query('SELECT NOW()');
    console.log('✅ PostgreSQL connected successfully!');

    // Read and run schema.sql
    const schemaPath = path.join(__dirname, '../../schema.sql');
    if (fs.existsSync(schemaPath)) {
      console.log('🔄 Initializing database schema...');
      const schemaSql = fs.readFileSync(schemaPath, 'utf8');
      await pool.query(schemaSql);
      console.log('✅ Database schema initialized successfully!');
    } else {
      console.warn('⚠️ schema.sql not found! Skipping schema initialization.');
    }

    // Seed default users if profiles table is empty
    const checkUsers = await pool.query('SELECT COUNT(*) FROM profiles');
    const userCount = parseInt(checkUsers.rows[0].count);

    if (userCount === 0) {
      console.log('🔄 Seeding default users (admin, support, user)...');
      
      const defaultPassword = 'password123';
      const hashedPassword = bcrypt.hashSync(defaultPassword, 10);

      const usersToSeed = [
        {
          id: '550e8400-e29b-41d4-a716-446655440000', // Static UUID for testing consistency
          name: 'John Customer',
          email: 'user@example.com',
          phone: '+6281234567890',
          department: 'IT Support',
          role: 'user',
          avatar: 'https://api.dicebear.com/7.x/adventurer/svg?seed=John',
        },
        {
          id: '660e8400-e29b-41d4-a716-446655440001',
          name: 'Sarah Support',
          email: 'support@example.com',
          phone: '+6289876543210',
          department: 'Customer Service',
          role: 'support',
          avatar: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Sarah',
        },
        {
          id: '770e8400-e29b-41d4-a716-446655440002',
          name: 'Alex Admin',
          email: 'admin@example.com',
          phone: '+6281112223334',
          department: 'Operations',
          role: 'admin',
          avatar: 'https://api.dicebear.com/7.x/adventurer/svg?seed=Alex',
        }
      ];

      for (const u of usersToSeed) {
        await pool.query(
          `INSERT INTO profiles (id, name, email, phone, department, role, avatar, password_hash)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [u.id, u.name, u.email, u.phone, u.department, u.role, u.avatar, hashedPassword]
        );
        console.log(`👤 Seeded ${u.role}: ${u.email} (Password: ${defaultPassword})`);
      }
      console.log('✅ Seeding complete!');
    }
  } catch (error) {
    console.error('❌ Database initialization error:', error.message);
    throw error;
  }
};

module.exports = {
  pool,
  query,
  initDb,
};
