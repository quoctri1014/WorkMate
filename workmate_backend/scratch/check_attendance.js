const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgres://postgres:1@localhost:5432/workmate_db'
});

async function checkAttendance() {
  const res = await pool.query("SELECT * FROM attendance WHERE DATE(check_in_time) = '2026-05-10'");
  console.log('--- Attendance on 2026-05-10 ---');
  console.log(res.rows);
  
  const res2 = await pool.query("SELECT * FROM approvals WHERE type = 'Quên chấm công'");
  console.log('\n--- Forgot Attendance Approvals ---');
  console.log(res2.rows);
  
  await pool.end();
}

checkAttendance();
