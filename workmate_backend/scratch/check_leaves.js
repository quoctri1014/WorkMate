const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgres://postgres:1@localhost:5432/workmate_db'
});

async function check() {
  const res = await pool.query("SELECT * FROM approvals WHERE status = 'approved'");
  console.log(JSON.stringify(res.rows, null, 2));
  await pool.end();
}

check();
