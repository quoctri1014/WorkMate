const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function resetApprovals() {
  try {
    console.log('🔄 Đang khởi tạo lại bảng approvals trong workmate_db...');
    
    // Xóa bảng cũ nếu nó bị lỗi cấu trúc nặng
    await pool.query('DROP TABLE IF EXISTS approvals;');
    
    // Tạo lại bảng với đầy đủ các cột cần thiết
    await pool.query(`
      CREATE TABLE approvals (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER,
        employee_name VARCHAR(255),
        type VARCHAR(100),
        reason TEXT,
        from_date TIMESTAMP,
        to_date TIMESTAMP,
        attachment_urls JSONB DEFAULT '[]',
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    console.log('✅ Bảng approvals đã được tạo mới thành công!');
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  } finally {
    await pool.end();
  }
}

resetApprovals();
