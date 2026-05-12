const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

async function checkOTData() {
  try {
    const result = await pool.query(
      "SELECT id, type, reason, from_date, total_hours FROM approvals WHERE type = 'Làm thêm giờ' ORDER BY from_date DESC"
    );
    console.log('--- OT Data in DB ---');
    result.rows.forEach(row => {
      console.log(`ID: ${row.id} | Type: ${row.type} | Reason: ${row.reason} | Date: ${row.from_date} | Hours: ${row.total_hours}`);
    });
  } catch (err) {
    console.error('❌ Lỗi:', err.message);
  } finally {
    await pool.end();
  }
}

checkOTData();
