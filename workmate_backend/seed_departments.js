require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

const departments = [
  {
    name: 'Phòng Nhân sự',
    code: 'HR',
    positions: ['Trưởng phòng Nhân sự', 'Chuyên viên tuyển dụng', 'Chuyên viên C&B', 'Nhân viên hành chính']
  },
  {
    name: 'Phòng Kế toán',
    code: 'ACC',
    positions: ['Kế toán trưởng', 'Kế toán tổng hợp', 'Kế toán kho', 'Nhân viên kế toán']
  },
  {
    name: 'Phòng Marketing & Truyền thông',
    code: 'MKT',
    positions: ['Trưởng phòng Marketing', 'Content Creator', 'Graphic Designer', 'Digital Marketing Specialist', 'Chuyên viên PR']
  },
  {
    name: 'Phòng Kinh doanh',
    code: 'SALES',
    positions: ['Trưởng phòng Kinh doanh', 'Nhân viên kinh doanh (Sales)', 'Chuyên viên chăm sóc khách hàng', 'Nhân viên Telesales']
  },
  {
    name: 'Phòng Kỹ thuật / IT',
    code: 'IT',
    positions: ['Trưởng phòng Kỹ thuật', 'Lập trình viên Fullstack', 'Chuyên viên hệ thống', 'Kỹ thuật viên IT Support']
  }
];

async function seed() {
  try {
    console.log('--- Đang thiết lập dữ liệu Phòng ban & Chức vụ ---');
    
    for (const dept of departments) {
      const check = await pool.query('SELECT id FROM departments WHERE name = $1 OR code = $2', [dept.name, dept.code]);
      
      if (check.rows.length > 0) {
        // Cập nhật nếu đã tồn tại
        await pool.query(
          'UPDATE departments SET positions = $1, code = $2 WHERE name = $3',
          [JSON.stringify(dept.positions), dept.code, dept.name]
        );
        console.log(`✅ Đã cập nhật chức vụ cho: ${dept.name}`);
      } else {
        // Thêm mới nếu chưa có
        await pool.query(
          'INSERT INTO departments (name, code, positions) VALUES ($1, $2, $3)',
          [dept.name, dept.code, JSON.stringify(dept.positions)]
        );
        console.log(`✨ Đã tạo mới: ${dept.name}`);
      }
    }

    console.log('\n🚀 TẤT CẢ ĐÃ SẴN SÀNG! Bạn có thể vào Web Admin để kiểm tra.');
  } catch (err) {
    console.error('❌ Lỗi thiết lập:', err.message);
  } finally {
    await pool.end();
  }
}

seed();
