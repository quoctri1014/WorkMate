const { Pool } = require('pg');
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function migrate() {
  try {
    await pool.query("ALTER TABLE meetings ADD COLUMN IF NOT EXISTS location VARCHAR(255)");
    console.log('✅ Successfully added location column to meetings table.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error migrating:', err.message);
    process.exit(1);
  }
}
migrate();
