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
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Thêm cột group_chat_id vào bảng departments
    await client.query('ALTER TABLE departments ADD COLUMN IF NOT EXISTS group_chat_id INTEGER REFERENCES conversations(id) ON DELETE SET NULL');

    // Lấy tất cả departments
    const depts = await client.query('SELECT * FROM departments');
    
    for (const dept of depts.rows) {
      let chatId = dept.group_chat_id;
      
      // Tạo group chat nếu chưa có
      if (!chatId) {
        const groupName = `Phòng ${dept.name}`;
        const chatRes = await client.query(
          `INSERT INTO conversations (type, name, created_by) VALUES ('group', $1, 1) RETURNING id`,
          [groupName]
        );
        chatId = chatRes.rows[0].id;
        
        await client.query('UPDATE departments SET group_chat_id = $1 WHERE id = $2', [chatId, dept.id]);
        console.log(`✅ Đã tạo group chat "${groupName}" (ID: ${chatId})`);
      }

      // Thêm tất cả nhân viên của phòng này vào group
      const emps = await client.query('SELECT id FROM employees WHERE department_id = $1', [dept.id]);
      for (const emp of emps.rows) {
        // Kiểm tra xem đã trong group chưa
        const check = await client.query('SELECT 1 FROM conversation_members WHERE conversation_id = $1 AND user_id = $2', [chatId, emp.id]);
        if (check.rows.length === 0) {
          await client.query('INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)', [chatId, emp.id]);
        }
      }
    }

    await client.query('COMMIT');
    console.log('🎉 Đã đồng bộ nhóm chat phòng ban thành công!');
  } catch(e) { 
    await client.query('ROLLBACK');
    console.error('❌ Lỗi:', e.message); 
  } finally { 
    client.release();
    pool.end(); 
  }
}
run();
