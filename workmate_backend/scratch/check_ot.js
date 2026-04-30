const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function check() {
  try {
    const r = await pool.query("SELECT * FROM approvals WHERE type = 'Làm thêm giờ'");
    console.log('OT REQUESTS FOUND:', r.rows.length);
    console.log(JSON.stringify(r.rows, null, 2));
    await pool.end();
  } catch (e) {
    console.error(e);
  }
}
check();
