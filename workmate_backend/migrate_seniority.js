const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function migrate() {
  try {
    await pool.query(`
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS seniority_points INTEGER DEFAULT 0;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS technical_score INTEGER DEFAULT 0;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS teamwork_score INTEGER DEFAULT 0;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS creativity_score INTEGER DEFAULT 0;
    `);
    console.log('✅ Migration completed!');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
  } finally {
    await pool.end();
  }
}

migrate();
