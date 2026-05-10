require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function run() {
  try {
    // Xem trước bản ghi hôm nay
    const check = await pool.query(`
      SELECT id, employee_id, employee_name, check_in_time, check_out_time
      FROM attendance
      WHERE DATE(check_in_time AT TIME ZONE 'Asia/Ho_Chi_Minh') = CURRENT_DATE
      ORDER BY check_in_time DESC
    `);

    if (check.rows.length === 0) {
      console.log('✅ Không có bản ghi chấm công nào hôm nay.');
    } else {
      console.log(`📋 Tìm thấy ${check.rows.length} bản ghi hôm nay:`);
      check.rows.forEach(r => {
        console.log(`  - ID: ${r.id} | NV: ${r.employee_name || r.employee_id} | Check-in: ${r.check_in_time} | Check-out: ${r.check_out_time || 'Chưa'}`);
      });

      // Xóa
      const del = await pool.query(`
        DELETE FROM attendance
        WHERE DATE(check_in_time AT TIME ZONE 'Asia/Ho_Chi_Minh') = CURRENT_DATE
      `);
      console.log(`\n🗑️  Đã xóa ${del.rowCount} bản ghi chấm công hôm nay thành công!`);
    }
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  } finally {
    pool.end();
  }
}

run();
