
const { Pool } = require('pg');
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function fix() {
  try {
    // 1. Swap from_date and to_date if they are reversed
    const res = await pool.query("UPDATE approvals SET from_date = to_date, to_date = from_date WHERE from_date > to_date");
    console.log(`✅ Fixed ${res.rowCount} reversed date ranges.`);
    
    // 2. Clear any total_hours that might be negative
    const res2 = await pool.query("UPDATE approvals SET total_hours = ABS(total_hours) WHERE total_hours < 0");
    console.log(`✅ Fixed ${res2.rowCount} negative total_hours.`);
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

fix();
