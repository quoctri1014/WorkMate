const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function deepCleanupOT() {
  try {
    const today = '2026-05-11';
    console.log(`🧹 Đang dọn dẹp triệt để lịch sử cho nhân viên ID 7...`);
    
    // Xóa tất cả các đơn (OT, nghỉ phép...) của nhân viên này trước ngày hôm nay
    // Hoặc có các lý do test phổ biến
    const result = await pool.query(
      "DELETE FROM approvals WHERE employee_id = 7 AND (DATE(from_date) < $1 OR reason IN ('test', '123', '456', 'test thôi ạ'))",
      [today]
    );
    
    console.log(`✅ Đã dọn dẹp thành công ${result.rowCount} bản ghi cũ/test.`);
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  } finally {
    await pool.end();
  }
}

deepCleanupOT();
