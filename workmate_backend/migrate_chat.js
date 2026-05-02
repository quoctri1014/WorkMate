const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function migrate() {
  try {
    console.log('🚀 Đang khởi tạo bảng chat_messages...');
    
    await pool.query(`
      CREATE TABLE IF NOT EXISTS chat_messages (
          id SERIAL PRIMARY KEY,
          sender_id INTEGER REFERENCES employees(id),
          receiver_id INTEGER REFERENCES employees(id),
          message TEXT NOT NULL,
          is_ai BOOLEAN DEFAULT FALSE,
          is_read BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('✅ Đã tạo bảng chat_messages thành công!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi migration:', err.message);
    process.exit(1);
  }
}

migrate();
