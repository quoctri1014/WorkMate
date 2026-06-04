require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const poolConfig = process.env.DATABASE_URL 
  ? { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } }
  : {
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: String(process.env.DB_PASSWORD),
      port: process.env.DB_PORT,
    };

const pool = new Pool(poolConfig);

async function seedData() {
  try {
    console.log("🚀 Bắt đầu seed dữ liệu mẫu cho Demo...");

    // Xóa dữ liệu cũ (Tùy chọn, ở đây ta cứ chèn thêm nếu chưa có, hoặc xóa bảng con trước)
    // Để an toàn, chỉ tạo dữ liệu nếu chưa có, hoặc xóa sạch rồi tạo lại.
    // Lần này ta sẽ xóa hết các bảng để làm demo sạch sẽ.
    console.log("🧹 Đang làm sạch database...");
    await pool.query('DELETE FROM chat_messages');
    await pool.query('DELETE FROM user_notifications');
    await pool.query('DELETE FROM notifications');
    await pool.query('DELETE FROM attendance');
    await pool.query('DELETE FROM approvals');
    await pool.query('DELETE FROM meetings');
    await pool.query('DELETE FROM employee_banks');
    await pool.query('DELETE FROM employees');
    await pool.query('DELETE FROM departments');

    // 1. Departments
    console.log("🏢 Đang tạo phòng ban...");
    const depts = [
      { name: 'Phòng Kỹ Thuật (IT)', code: 'IT', positions: '["Developer", "Tester", "DevOps"]' },
      { name: 'Phòng Nhân Sự (HR)', code: 'HR', positions: '["HR Manager", "Recruiter", "Admin"]' },
      { name: 'Phòng Kinh Doanh', code: 'SALES', positions: '["Sales Manager", "Sales Executive"]' },
      { name: 'Ban Giám Đốc', code: 'BOD', positions: '["CEO", "CTO", "CFO"]' }
    ];
    
    let deptIds = {};
    for (let d of depts) {
      const res = await pool.query(
        'INSERT INTO departments (name, code, positions) VALUES ($1, $2, $3) RETURNING id',
        [d.name, d.code, d.positions]
      );
      deptIds[d.code] = res.rows[0].id;
    }

    // 2. Employees
    console.log("👥 Đang tạo nhân viên...");
    const salt = await bcrypt.genSalt(10);
    const defaultPassword = await bcrypt.hash('123456', salt);

    const emps = [
      { code: 'NV001', name: 'Nguyễn Quốc Trí', email: 'tri@workmate.com', phone: '0901234567', dept_id: deptIds['IT'], dept_name: 'Phòng Kỹ Thuật (IT)', pos: 'Developer', role: 'admin' },
      { code: 'NV002', name: 'Trần Thị Thu Phương', email: 'phuong@workmate.com', phone: '0901234568', dept_id: deptIds['HR'], dept_name: 'Phòng Nhân Sự (HR)', pos: 'HR Manager', role: 'admin' },
      { code: 'NV003', name: 'Lê Văn Cường', email: 'cuong@workmate.com', phone: '0901234569', dept_id: deptIds['SALES'], dept_name: 'Phòng Kinh Doanh', pos: 'Sales Executive', role: 'user' },
      { code: 'NV004', name: 'Phạm Minh Hùng', email: 'hung@workmate.com', phone: '0901234570', dept_id: deptIds['BOD'], dept_name: 'Ban Giám Đốc', pos: 'CEO', role: 'admin' },
      { code: 'NV005', name: 'Hoàng Minh Tuấn', email: 'tuan@workmate.com', phone: '0901234571', dept_id: deptIds['IT'], dept_name: 'Phòng Kỹ Thuật (IT)', pos: 'Tester', role: 'user' },
      { code: 'NV006', name: 'Đặng Mai Lan', email: 'lan@workmate.com', phone: '0901234572', dept_id: deptIds['HR'], dept_name: 'Phòng Nhân Sự (HR)', pos: 'Admin', role: 'user' },
      { code: 'NV007', name: 'Vũ Quốc Khánh', email: 'khanh@workmate.com', phone: '0901234573', dept_id: deptIds['SALES'], dept_name: 'Phòng Kinh Doanh', pos: 'Sales Executive', role: 'user' }
    ];

    let empIds = {};
    for (let e of emps) {
      const res = await pool.query(
        `INSERT INTO employees (employee_code, name, email, password_hash, phone, department_id, department_name, position, role, face_registered_at, join_date, seniority_points)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), '2023-01-15', 50) RETURNING id`,
        [e.code, e.name, e.email, defaultPassword, e.phone, e.dept_id, e.dept_name, e.pos, e.role]
      );
      empIds[e.code] = res.rows[0].id;
    }

    // 3. Attendance (Chấm công giả lập cho 7 ngày qua)
    console.log("⏱️ Đang tạo dữ liệu chấm công...");
    for (let i = 0; i < 7; i++) {
      let d = new Date();
      d.setDate(d.getDate() - i);
      let dateStr = d.toISOString().split('T')[0];

      // Bỏ qua Chủ Nhật
      if (d.getDay() === 0) continue;

      for (let code in empIds) {
        // NV007 nghỉ 2 ngày gần đây
        if (code === 'NV007' && i < 2) continue;

        let checkInTime = `${dateStr} 08:${Math.floor(Math.random() * 20 + 10)}:00`;
        let checkOutTime = `${dateStr} 17:${Math.floor(Math.random() * 30 + 30)}:00`;
        
        await pool.query(
          `INSERT INTO attendance (employee_id, employee_name, check_in_time, check_out_time, check_in_method)
           VALUES ($1, $2, $3, $4, $5)`,
          [empIds[code], emps.find(e=>e.code===code).name, checkInTime, checkOutTime, 'FACE_ID']
        );
      }
    }

    // 4. Approvals (Đơn từ)
    console.log("📝 Đang tạo đơn từ...");
    await pool.query(
      `INSERT INTO approvals (employee_id, employee_name, name, type, reason, status, created_at, is_half_day, total_hours)
       VALUES ($1, $2, $3, $4, $5, $6, NOW(), false, 8)`,
      [empIds['NV007'], 'Vũ Quốc Khánh', 'Đơn xin nghỉ phép 2 ngày', 'Nghỉ phép', 'Giải quyết việc gia đình', 'approved']
    );
    await pool.query(
      `INSERT INTO approvals (employee_id, employee_name, name, type, reason, status, created_at, is_half_day, total_hours)
       VALUES ($1, $2, $3, $4, $5, $6, NOW(), true, 4)`,
      [empIds['NV005'], 'Hoàng Minh Tuấn', 'Xin về sớm đi khám bệnh', 'Nghỉ bệnh', 'Bệnh viện hẹn tái khám', 'pending']
    );
    await pool.query(
      `INSERT INTO approvals (employee_id, employee_name, name, type, reason, status, created_at, is_half_day, total_hours)
       VALUES ($1, $2, $3, $4, $5, $6, NOW(), false, 8)`,
      [empIds['NV003'], 'Lê Văn Cường', 'Đơn đi công tác', 'Công tác', 'Gặp khách hàng tại Q1', 'rejected']
    );

    // 5. Meetings
    console.log("📅 Đang tạo lịch họp...");
    let tmr = new Date(); tmr.setDate(tmr.getDate() + 1); tmr.setHours(10, 0, 0, 0);
    await pool.query(
      `INSERT INTO meetings (title, content, start_time, location, department_ids, is_online)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      ['Họp giao ban toàn bộ phận', 'Báo cáo tiến độ dự án WorkMate quý 2', tmr.toISOString(), 'Phòng họp lớn Lầu 3', JSON.stringify([deptIds['IT'], deptIds['SALES'], deptIds['BOD']]), false]
    );

    // 6. Notifications
    console.log("🔔 Đang tạo thông báo...");
    await pool.query(
      `INSERT INTO notifications (title, content, department_ids)
       VALUES ($1, $2, $3)`,
      ['Thông báo thưởng Lễ 30/4', 'Mỗi CBNV sẽ được thưởng 1.000.000 VNĐ vào ngày 28/04.', '[]']
    );

    console.log("🎉 Seed dữ liệu Demo THÀNH CÔNG! Đã có đủ dữ liệu để báo cáo.");
    process.exit(0);
  } catch (err) {
    console.error("❌ Lỗi khi seed dữ liệu:", err);
    process.exit(1);
  }
}

seedData();
