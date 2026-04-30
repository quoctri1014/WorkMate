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
    const employees = await pool.query('SELECT id, name, employee_code FROM employees');
    const departments = await pool.query('SELECT id, name FROM departments');
    console.log('--- EMPLOYEES ---');
    console.table(employees.rows);
    console.log('--- DEPARTMENTS ---');
    console.table(departments.rows);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}
check();
