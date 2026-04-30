require('dotenv').config();
const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function setupSafeZone() {
  try {
    console.log('🚀 Đang thiết lập Safe Zone (GPS & WiFi)...');
    
    // Tạo bảng cấu hình nếu chưa có
    await pool.query(`
      CREATE TABLE IF NOT EXISTS company_config (
        id SERIAL PRIMARY KEY,
        company_name VARCHAR(255) DEFAULT 'WorkMate HQ',
        safe_lat DOUBLE PRECISION,
        safe_lng DOUBLE PRECISION,
        safe_wifi_ssid VARCHAR(255),
        radius_meters INT DEFAULT 100
      );

      // Xóa dữ liệu cũ và chèn dữ liệu mẫu (Tọa độ Landmark 81 - HCM)
      TRUNCATE company_config;
      INSERT INTO company_config (safe_lat, safe_lng, safe_wifi_ssid, radius_meters) 
      VALUES (10.7946, 106.7218, 'WorkMate_Office_5G', 200);
    `);
    
    console.log('✅ Thiết lập Safe Zone thành công!');
    console.log('📍 Tọa độ: 10.7946, 106.7218');
    console.log('📶 WiFi: WorkMate_Office_5G');
  } catch (err) {
    console.error('❌ Lỗi:', err);
  } finally {
    await pool.end();
  }
}

setupSafeZone();
