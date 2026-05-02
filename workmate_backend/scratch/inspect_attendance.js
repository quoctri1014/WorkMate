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
    const res = await pool.query("SELECT * FROM attendance ORDER BY id DESC LIMIT 5");
    console.log('--- LATEST ATTENDANCE ---');
    console.table(res.rows);
  } catch (e) {
    console.error(e);
  } finally {
    await pool.end();
  }
}

check();
