const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function deleteOTHistory() {
  try {
    const today = '2026-05-11';
    console.log(`🧹 Đang xóa lịch sử đăng ký OT trước ngày ${today}...`);
    
    const result = await pool.query(
      "DELETE FROM approvals WHERE type = 'Làm thêm giờ' AND DATE(from_date) < $1",
      [today]
    );
    
    console.log(`✅ Đã xóa thành công ${result.rowCount} bản ghi OT lịch sử.`);
  } catch (err) {
    console.error('❌ Lỗi khi xóa lịch sử OT:', err.message);
  } finally {
    await pool.end();
  }
}

deleteOTHistory();
