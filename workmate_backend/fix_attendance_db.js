require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function fix() {
  try {
    console.log('--- Đang kiểm tra và sửa cấu trúc bảng attendance ---');
    await pool.query(`
      ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_out_time TIMESTAMP;
      ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_method VARCHAR(50);
    `);
    console.log('✅ Đã thêm các cột: check_in_time, check_out_time, check_in_method');
    
    // Kiểm tra lại
    const res = await pool.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'attendance'");
    console.log('Các cột hiện tại trong bảng attendance:', res.rows.map(r => r.column_name).join(', '));
    
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  } finally {
    await pool.end();
  }
}

fix();
