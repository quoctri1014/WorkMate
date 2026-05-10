const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgres://postgres:1@localhost:5432/workmate_db'
});

async function testCount() {
  const employee_id = 7;
  const month = '2026-05';
  const res = await pool.query(
    "SELECT COUNT(*) FROM approvals WHERE employee_id = $1 AND type = 'Quên chấm công' AND status != 'rejected' AND to_char(created_at, 'YYYY-MM') = $2",
    [employee_id, month]
  );
  console.log(`Count for ${employee_id} in ${month}:`, res.rows[0].count);
  
  const res2 = await pool.query("SELECT id, type, status, created_at, to_char(created_at, 'YYYY-MM') as m FROM approvals WHERE employee_id = 7");
  console.log('\nAll approvals for user 7:');
  console.log(res2.rows);
  
  await pool.end();
}

testCount();
