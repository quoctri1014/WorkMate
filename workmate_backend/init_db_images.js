const { Pool } = require('pg');
const fs = require('fs-extra');
const path = require('path');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'workmate_db',
  password: process.env.DB_PASSWORD || '123',
  port: process.env.DB_PORT || 5432,
});

async function init() {
  try {
    console.log('--- KHỞI TẠO CƠ SỞ DỮ LIỆU VÀ THƯ MỤC ẢNH ---');
    
    // 1. Tạo thư mục uploads
    const uploadDir = path.join(__dirname, 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir);
      console.log('✅ Đã tạo thư mục uploads');
    } else {
      console.log('ℹ️ Thư mục uploads đã tồn tại');
    }

    // 2. Thêm cột vào database
    console.log('⌛ Đang cập nhật cấu trúc bảng...');
    await pool.query(`
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(255);
      ALTER TABLE approvals ADD COLUMN IF NOT EXISTS attachment_urls JSONB DEFAULT '[]';
    `);
    console.log('✅ Đã thêm các cột avatar_url và attachment_urls thành công');

    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
    process.exit(1);
  }
}

init();
