const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate',
  password: 'admin', // Thay bằng password của bạn
  port: 5432,
});

async function fixSchema() {
  try {
    console.log('🔄 Đang cập nhật schema cho bảng approvals...');
    
    // Thêm cột employee_name nếu chưa có
    await pool.query(`
      ALTER TABLE approvals 
      ADD COLUMN IF NOT EXISTS employee_name VARCHAR(255);
    `);
    
    console.log('✅ Cập nhật schema thành công!');
  } catch (err) {
    console.error('❌ Lỗi cập nhật schema:', err);
  } finally {
    await pool.end();
  }
}

fixSchema();
