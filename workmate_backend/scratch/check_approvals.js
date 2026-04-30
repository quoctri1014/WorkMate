
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
    const res = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'approvals'");
    console.log(JSON.stringify(res.rows, null, 2));
    
    const res2 = await pool.query("SELECT employee_id, type, status, total_hours FROM approvals WHERE status = 'approved'");
    console.log('Approved Approvals:');
    console.log(JSON.stringify(res2.rows, null, 2));
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

check();
