const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: 'postgres://postgres:1@localhost:5432/workmate_db'
});

async function checkCols() {
  const res = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'approvals'");
  console.log('--- Approvals Columns ---');
  res.rows.forEach(r => console.log(`${r.column_name}: ${r.data_type}`));
  
  const res2 = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'attendance'");
  console.log('\n--- Attendance Columns ---');
  res2.rows.forEach(r => console.log(`${r.column_name}: ${r.data_type}`));
  
  await pool.end();
}

checkCols();
