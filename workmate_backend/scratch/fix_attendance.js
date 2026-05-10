const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgres://postgres:1@localhost:5432/workmate_db'
});

async function fixAttendance() {
  // Tìm đơn quên chấm công đã duyệt nhưng chưa có trong bảng attendance
  const res = await pool.query("SELECT * FROM approvals WHERE type = 'Quên chấm công' AND status = 'approved' AND id NOT IN (SELECT CAST(REGEXP_REPLACE(check_in_method, '.*ID: ', '') AS INTEGER) FROM attendance WHERE check_in_method LIKE '%ID: %')");
  // Wait, I didn't store ID in check_in_method before.
  
  // Let's just find the one from the check_attendance.js output
  const approval = {
    employee_id: 7,
    employee_name: 'Lê Quốc Trí ',
    from_date: '2026-05-10 08:00:00',
    to_date: '2026-05-10 17:30:00'
  };

  try {
    await pool.query(
      "INSERT INTO attendance (employee_id, employee_name, check_in_time, check_out_time, check_in_method) VALUES ($1, $2, $3, $4, 'Quản trị viên bổ sung')",
      [approval.employee_id, approval.employee_name, approval.from_date, approval.to_date]
    );
    console.log('✅ Đã bổ sung bản ghi chấm công thiếu.');
  } catch (err) {
    console.error('❌ Lỗi bổ sung:', err);
  }
  
  await pool.end();
}

fixAttendance();
