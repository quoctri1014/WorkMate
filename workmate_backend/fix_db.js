require('dotenv').config();
const { Pool } = require('pg');
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

async function run() {
  try {
    // Sửa các tin nhắn do người dùng gửi cho AI (receiver_id = 0)
    await pool.query("UPDATE chat_messages SET chat_type='ai' WHERE receiver_id=0");
    // Xóa các tin nhắn AI cũ nhưng bị dính vào admin do chưa có receiver_id và is_ai=false
    // Có thể xóa luôn những tin chat_type = 'admin' mà có nội dung là câu hỏi cho AI (VD: "Hôm nay chấm công chưa")
    await pool.query(`UPDATE chat_messages SET chat_type='ai' WHERE message IN ('Hôm nay chấm công chưa?', 'Còn mấy ngày phép?', 'Xem đơn từ của tôi', 'Còn mấy ngày nghỉ phép', 'sỗ ngày nghỉ phép còn lại?')`);
    console.log('✅ Đã sửa phân luồng DB!');
  } catch(e) { console.error(e.message); }
  finally { pool.end(); }
}
run();
