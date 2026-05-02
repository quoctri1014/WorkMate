const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function clearToday() {
  try {
    // Xóa tất cả các bản ghi có ngày trùng với hôm nay (Vietnam Time)
    const res = await pool.query(`
      DELETE FROM attendance 
      WHERE DATE(check_in_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::DATE
    `);
    console.log(`✅ Đã xóa ${res.rowCount} bản ghi chấm công của ngày hôm nay.`);
  } catch (e) {
    console.error('❌ Lỗi khi xóa dữ liệu:', e);
  } finally {
    await pool.end();
  }
}

clearToday();
