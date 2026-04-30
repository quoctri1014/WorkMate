const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function checkEmployees() {
  try {
    const res = await pool.query('SELECT id, name, employee_code, email FROM employees ORDER BY id');
    console.table(res.rows);
    await pool.end();
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

checkEmployees();
