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
    console.log('--- Đang kiểm tra và bổ sung cột birthday ---');
    await pool.query("ALTER TABLE employees ADD COLUMN IF NOT EXISTS birthday DATE");
    console.log('✅ Đã bổ sung cột birthday (nếu chưa có)');
    
    // Kiểm tra lại dữ liệu
    const res = await pool.query("SELECT id, name FROM employees WHERE employee_code = 'IT267562'");
    console.log('Nhân viên IT267562:', res.rows[0]);
  } catch (err) {
    console.error('❌ Lỗi:', err);
  } finally {
    await pool.end();
  }
}

fix();
