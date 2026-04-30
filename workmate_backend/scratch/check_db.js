const { Pool } = require('pg');
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function check() {
  try {
    const employees = await pool.query('SELECT count(*) FROM employees');
    const departments = await pool.query('SELECT count(*) FROM departments');
    console.log('Employees count:', employees.rows[0].count);
    console.log('Departments count:', departments.rows[0].count);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}
check();
