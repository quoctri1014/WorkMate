const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function test() {
  try {
    const res = await pool.query(`
      SELECT data_type 
      FROM information_schema.columns 
      WHERE table_name = 'attendance' AND column_name = 'check_in_time'
    `);
    console.log(res.rows[0]);
  } finally {
    pool.end();
  }
}
test();
