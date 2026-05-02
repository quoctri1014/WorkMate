require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function main() {
  try {
    const res = await pool.query('SELECT * FROM attendance');
    console.log("ALL ATTENDANCE RECORDS:");
    console.table(res.rows.map(r => ({ id: r.id, employee_id: r.employee_id, check_in: r.check_in_time })));
  } catch (e) {
    console.error(e);
  } finally {
    pool.end();
  }
}
main();
