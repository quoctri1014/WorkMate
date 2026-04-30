
const { Pool } = require('pg');
const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'workmate_db',
  password: '1',
  port: 5432,
});

async function reset() {
  try {
    console.log('🔄 Đang reset tất cả ngày nghỉ phép...');
    
    // Xóa tất cả các đơn nghỉ phép (LOWER(type) LIKE '%nghỉ%' OR LOWER(type) LIKE '%phép%')
    const res = await pool.query(`
      DELETE FROM approvals 
      WHERE (LOWER(type) LIKE '%nghỉ%' OR LOWER(type) LIKE '%phép%')
      AND LOWER(type) NOT LIKE '%thêm%'
    `);
    
    console.log(`✅ Đã xóa ${res.rowCount} đơn nghỉ phép.`);
    console.log('✅ Số ngày nghỉ phép của tất cả nhân viên đã được reset về 12 ngày.');
    
    process.exit(0);
  } catch (err) {
    console.error('❌ Lỗi:', err);
    process.exit(1);
  }
}

reset();
