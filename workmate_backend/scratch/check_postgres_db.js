const { Pool } = require('pg');
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'postgres',
  password: '1',
  port: 5432,
});

async function check() {
  try {
    const res = await pool.query("SELECT count(*) FROM employees");
    console.log('Employees in postgres DB:', res.rows[0].count);
    process.exit(0);
  } catch (err) {
    console.log('No employees table in postgres DB');
    process.exit(0);
  }
}
check();
