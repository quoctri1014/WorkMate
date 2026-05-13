
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function seedNotifications() {
  try {
    // 1. Lấy tất cả nhân viên
    const empRes = await pool.query('SELECT id, department_id FROM employees');
    if (empRes.rows.length === 0) {
      console.log('❌ Không tìm thấy nhân viên nào.');
      return;
    }

    console.log(`🌱 Đang tạo thông báo mẫu cho ${empRes.rows.length} nhân viên...`);

    for (const emp of empRes.rows) {
      const empId = emp.id;
      const deptId = emp.department_id;

      // Tạo thông báo cá nhân (Phê duyệt)
      await pool.query(
        "INSERT INTO user_notifications (employee_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5)",
        [empId, '✅ Đơn nghỉ phép đã được duyệt', 'Yêu cầu nghỉ phép ngày 15/05 của bạn đã được Admin phê duyệt.', 'approval', JSON.stringify({ status: 'approved' })]
      );

      // Tạo thông báo lịch họp
      await pool.query(
        "INSERT INTO user_notifications (employee_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5)",
        [empId, '📅 Lịch họp mới', 'Cuộc họp định kỳ hàng tuần sẽ diễn ra vào 9:00 sáng mai tại phòng họp chính.', 'meeting', JSON.stringify({ meeting_id: 101 })]
      );
    }

    console.log('✅ Đã tạo xong dữ liệu mẫu! Hãy quay lại App và kéo để làm mới.');
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  } finally {
    await pool.end();
  }
}

seedNotifications();
