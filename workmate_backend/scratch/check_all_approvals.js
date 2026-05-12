const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function checkAllApprovals() {
  try {
    const result = await pool.query(
      "SELECT id, type, reason, from_date, total_hours, employee_id FROM approvals ORDER BY id DESC LIMIT 20"
    );
    console.log('--- Last 20 Approvals in DB ---');
    result.rows.forEach(row => {
      console.log(`ID: ${row.id} | Emp: ${row.employee_id} | Type: [${row.type}] | Reason: ${row.reason} | Date: ${row.from_date} | Hours: ${row.total_hours}`);
    });
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  } finally {
    await pool.end();
  }
}

checkAllApprovals();
