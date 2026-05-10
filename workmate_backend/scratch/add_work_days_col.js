const { Pool } = require('pg');
const pool = new Pool({
  connectionString: 'postgres://postgres:1@localhost:5432/workmate_db'
});

async function migrate() {
  try {
    await pool.query("ALTER TABLE company_config ADD COLUMN IF NOT EXISTS work_days TEXT DEFAULT '[1,2,3,4,5,6]'");
    console.log("Column work_days added successfully");
  } catch (err) {
    console.error("Error adding column:", err);
  } finally {
    await pool.end();
  }
}

migrate();
