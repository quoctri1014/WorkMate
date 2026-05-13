
const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function createTables() {
  try {
    console.log('🛠️ Đang tạo các bảng thông báo...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        department_ids JSONB DEFAULT '[]',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS user_notifications (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        type VARCHAR(50),
        data JSONB DEFAULT '{}',
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Đã tạo bảng thành công!');
  } catch (err) {
    console.error('❌ Lỗi tạo bảng:', err.message);
  } finally {
    await pool.end();
  }
}

createTables();
