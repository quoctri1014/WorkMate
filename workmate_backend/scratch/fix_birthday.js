const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'workmate',
  password: process.env.DB_PASSWORD || '123456',
  port: process.env.DB_PORT || 5432,
});

async function fix() {
  try {
    const birthday = '1995-05-20';
    await pool.query("UPDATE employees SET birthday = $1 WHERE employee_code = 'IT267562'", [birthday]);
    console.log('✅ Đã cập nhật ngày sinh mẫu cho IT267562');
  } catch (err) {
    console.error('❌ Lỗi:', err);
  } finally {
    await pool.end();
  }
}

fix();
