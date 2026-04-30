
const { Pool } = require('pg');
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function testQuery(employeeId) {
  try {
    const query = `SELECT 
        SUM(
          COALESCE(total_hours, 
            CASE 
              WHEN is_half_day = true THEN 4
              ELSE (EXTRACT(DAY FROM (to_date::timestamp - from_date::timestamp)) + 1) * 8
            END
          )
        ) as used 
       FROM approvals 
       WHERE employee_id = $1 AND status = 'approved' AND type != 'Làm thêm giờ'`;
    
    const res = await pool.query(query, [employeeId]);
    console.log('Query result for ID ' + employeeId + ':');
    console.log(JSON.stringify(res.rows, null, 2));
    
    const allRows = await pool.query("SELECT * FROM approvals WHERE employee_id = $1", [employeeId]);
    console.log('All rows for ID ' + employeeId + ':');
    console.log(allRows.rows.length + ' rows found');
    
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

testQuery(7);
