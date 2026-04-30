require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function migrate() {
  try {
    console.log('🚀 Đang chạy migration Face ID...');
    await pool.query(`
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS face_embedding JSONB;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS face_registered_at TIMESTAMPTZ;

      CREATE TABLE IF NOT EXISTS attendance_logs (
        id SERIAL PRIMARY KEY,
        employee_id INT REFERENCES employees(id),
        status VARCHAR(50),
        confidence NUMERIC(5,2),
        distance NUMERIC(8,4),
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);
    console.log('✅ Migration thành công!');
  } catch (err) {
    console.error('❌ Migration thất bại:', err);
  } finally {
    await pool.end();
  }
}

migrate();
