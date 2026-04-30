const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function checkNotifications() {
  try {
    const res = await pool.query("SELECT id, title, created_at FROM notifications ORDER BY id DESC LIMIT 5");
    console.table(res.rows);
    await pool.end();
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

checkNotifications();
