const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function testLogin() {
  const email = 'admin@workmate.com';
  const password = '123456';
  
  try {
    console.log(`🔍 Đang kiểm tra tài khoản: ${email}`);
    const r = await pool.query('SELECT * FROM employees WHERE email = $1', [email]);
    
    if (r.rows.length === 0) {
      console.log('❌ Không tìm thấy email này trong Database!');
    } else {
      const user = r.rows[0];
      console.log('✅ Tìm thấy user:', user.name, '(ID:', user.id, ')');
      const valid = await bcrypt.compare(password, user.password_hash);
      if (valid) {
        console.log('✅ Mật khẩu CHÍNH XÁC!');
      } else {
        console.log('❌ Mật khẩu SAI!');
      }
    }
    await pool.end();
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  }
}

testLogin();
