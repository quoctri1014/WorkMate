require('dotenv').config();
const { Pool } = require('pg');
const bcrypt = require('bcrypt');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function setup() {
  const email = 'admin@workmate.com';
  const password = '123456';
  const saltRounds = 10;
  
  try {
    console.log('--- Đang khởi tạo tài khoản Admin ---');
    const hash = await bcrypt.hash(password, saltRounds);
    
    // 1. Tạo phòng ban nếu chưa có
    await pool.query("INSERT INTO departments (name, code, positions) VALUES ('Quản trị', 'ADMIN', '[\"Giám đốc\"]') ON CONFLICT (code) DO NOTHING");
    
    // 2. Cập nhật hoặc tạo mới Admin
    const check = await pool.query('SELECT id FROM employees WHERE email = $1', [email]);
    
    if (check.rows.length > 0) {
      await pool.query('UPDATE employees SET password_hash = $1 WHERE email = $2', [hash, email]);
      console.log('✅ Đã CẬP NHẬT mật khẩu cho:', email);
    } else {
      await pool.query(
        'INSERT INTO employees (employee_code, name, email, password_hash, role, department_name, position) VALUES ($1, $2, $3, $4, $5, $6, $7)',
        ['AD001', 'Admin Hệ Thống', email, hash, 'admin', 'Quản trị', 'Giám đốc']
      );
      console.log('✅ Đã TẠO MỚI tài khoản Admin:', email);
    }
    
    console.log('👉 Bây giờ bạn hãy đăng nhập với mật khẩu: 123456');
    process.exit();
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
    process.exit(1);
  }
}

setup();
