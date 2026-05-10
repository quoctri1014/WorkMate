require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});
pool.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'chat_messages'").then(r => {
  console.log(r.rows.map(x => x.column_name));
  pool.end();
});
