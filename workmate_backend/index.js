require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const fs = require('fs-extra');
const nodemailer = require('nodemailer');

// Đảm bảo thư mục upload tồn tại
const uploadDirs = ['uploads', 'uploads/avatars', 'uploads/chat', 'uploads/attendance', 'uploads/notifications', 'uploads/approvals'];
uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let dest = 'uploads/';
    if (file.fieldname === 'avatar') dest = 'uploads/avatars/';
    else if (file.fieldname === 'file') dest = 'uploads/chat/';
    else if (file.fieldname === 'attendance') dest = 'uploads/attendance/';
    else if (file.fieldname === 'notification') dest = 'uploads/notifications/';
    else if (file.fieldname === 'approval') dest = 'uploads/approvals/';
    cb(null, dest);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage });
const admin = require('firebase-admin');
const ExcelJS = require('exceljs');

// --- CẤU HÌNH FIREBASE ---
try {
  let serviceAccount;
  if (process.env.FIREBASE_CONFIG) {
    serviceAccount = JSON.parse(process.env.FIREBASE_CONFIG);
  } else if (fs.existsSync(path.join(__dirname, "firebase-service-account.json"))) {
    serviceAccount = require("./firebase-service-account.json");
  }

  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log("🔥 Firebase Admin initialized successfully");
  } else {
    console.warn("⚠️ Firebase configuration not found.");
  }
} catch (err) {
  console.error("❌ Firebase Init Error:", err.message);
}
// OLD CODE REMOVED

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// --- CẤU HÌNH EMAIL ---
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// --- CẤU HÌNH HỆ THỐNG ---
const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });
const onlineUsers = new Map(); // socket.id -> user_id

io.on('connection', (socket) => {
  console.log('🔌 New client connected:', socket.id);

  socket.on('register', (userId) => {
    if (userId) {
      const id = Number(userId);
      onlineUsers.set(socket.id, id);
      console.log(`👤 User registered as online: ${id}`);
      io.emit('online_users', Array.from(new Set(onlineUsers.values())));
    }
  });

  socket.on('get_online_users', () => {
    socket.emit('online_users', Array.from(new Set(onlineUsers.values())));
  });

  socket.on('send_message', async (data) => {
    try {
      const { sender_id, receiver_id, message, is_ai, chat_type, conversation_id, message_type, file_url } = data;
      const r = await pool.query(
        "INSERT INTO chat_messages (sender_id, receiver_id, message, is_ai, chat_type, conversation_id, message_type, file_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *",
        [sender_id, receiver_id, message, is_ai || false, chat_type || 'admin', conversation_id || null, message_type || 'text', file_url || null]
      );
      const newMessage = r.rows[0];
      
      if (conversation_id) {
        io.emit(`receive_message_conv_${conversation_id}`, newMessage);
      } else if (receiver_id) {
        io.emit(`receive_message_${receiver_id}`, newMessage);
      } else if (chat_type === 'admin') {
        // Gửi cho tất cả Admin
        io.emit('receive_message_admin', newMessage);
      }
      io.emit(`receive_message_${sender_id}`, newMessage);
    } catch (err) {
      console.error('❌ Socket Error:', err.message);
    }
  });

  socket.on('recall_message', async (data) => {
    try {
      const { message_id } = data;
      const msgRes = await pool.query("SELECT * FROM chat_messages WHERE id = $1", [message_id]);
      if (msgRes.rows.length === 0) return;
      
      const msg = msgRes.rows[0];
      const now = new Date();
      const sentAt = new Date(msg.created_at);
      const diff = (now - sentAt) / (1000 * 60 * 60); // hours
      
      if (diff > 1) {
        socket.emit('error_message', { message: 'Chỉ có thể thu hồi tin nhắn trong vòng 1 tiếng.' });
        return;
      }
      
      await pool.query("UPDATE chat_messages SET is_recalled = true, message = 'Tin nhắn đã được thu hồi' WHERE id = $1", [message_id]);
      
      const updatedMsg = { ...msg, is_recalled: true, message: 'Tin nhắn đã được thu hồi' };
      
      if (msg.conversation_id) {
        io.emit(`message_recalled_conv_${msg.conversation_id}`, updatedMsg);
      } else if (msg.receiver_id) {
        io.emit(`message_recalled_${msg.receiver_id}`, updatedMsg);
        io.emit(`message_recalled_${msg.sender_id}`, updatedMsg);
      } else if (msg.chat_type === 'admin') {
        io.emit('message_recalled_admin', updatedMsg);
        io.emit(`message_recalled_${msg.sender_id}`, updatedMsg);
      } else if (msg.chat_type === 'ai') {
        io.emit(`message_recalled_${msg.sender_id}`, updatedMsg);
      }
    } catch (err) {
      console.error('❌ Recall Error:', err.message);
    }
  });

  socket.on('disconnect', () => {
    if (onlineUsers.has(socket.id)) {
      const userId = onlineUsers.get(socket.id);
      onlineUsers.delete(socket.id);
      console.log(`👋 User disconnected: ${userId}`);
      io.emit('online_users', Array.from(new Set(onlineUsers.values())));
    }
  });
});

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.get('/test', (req, res) => res.send('OK'));


app.post('/api/upload', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
  const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
  res.json({ url: fileUrl });
});

const poolConfig = process.env.DATABASE_URL 
  ? { connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } }
  : {
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: String(process.env.DB_PASSWORD),
      port: process.env.DB_PORT,
    };

const pool = new Pool(poolConfig);








// --- UTILS ---
function euclideanDistance(a, b) {
  if (a.length !== b.length) return 1.0;
  let sum = 0;
  for (let i = 0; i < a.length; i++) {
    const diff = a[i] - b[i];
    sum += diff * diff;
  }
  return Math.sqrt(sum);
}

function cosineSimilarity(a, b) {
  if (a.length !== b.length) return 0;
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

const MATCH_THRESHOLD = 0.75; // Thay đổi sang Cosine Similarity threshold

// --- DATABASE MIGRATION (Tự động nâng cấp cấu trúc) ---
const initDB = async () => {
  try {
    await pool.query(`
      ALTER TABLE meetings ADD COLUMN IF NOT EXISTS content TEXT;
      ALTER TABLE meetings ADD COLUMN IF NOT EXISTS department_ids JSONB DEFAULT '[]';
      ALTER TABLE approvals ADD COLUMN IF NOT EXISTS employee_name VARCHAR(255);
      ALTER TABLE approvals ADD COLUMN IF NOT EXISTS attachment_urls JSONB DEFAULT '[]';
      ALTER TABLE meetings ADD COLUMN IF NOT EXISTS start_time TIMESTAMP;
      ALTER TABLE meetings ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT FALSE;
      ALTER TABLE meetings ADD COLUMN IF NOT EXISTS location VARCHAR(255);
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS face_embedding JSONB;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS join_date DATE;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS birthday DATE;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS phone VARCHAR(255);
      ALTER TABLE departments ADD COLUMN IF NOT EXISTS positions JSONB DEFAULT '[]';
      CREATE TABLE IF NOT EXISTS company_config (id SERIAL PRIMARY KEY);
      ALTER TABLE company_config ADD COLUMN IF NOT EXISTS company_name VARCHAR(255);
      ALTER TABLE company_config ADD COLUMN IF NOT EXISTS safe_lat DOUBLE PRECISION;
      ALTER TABLE company_config ADD COLUMN IF NOT EXISTS safe_lng DOUBLE PRECISION;
      ALTER TABLE company_config ADD COLUMN IF NOT EXISTS safe_wifi_ssid VARCHAR(255);
      ALTER TABLE company_config ADD COLUMN IF NOT EXISTS safe_wifi_bssid VARCHAR(255);
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(255);
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS seniority_points INTEGER DEFAULT 0;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS technical_score INTEGER DEFAULT 0;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS teamwork_score INTEGER DEFAULT 0;
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS creativity_score INTEGER DEFAULT 0;
      ALTER TABLE approvals ADD COLUMN IF NOT EXISTS is_half_day BOOLEAN DEFAULT FALSE;
      ALTER TABLE approvals ADD COLUMN IF NOT EXISTS total_hours DOUBLE PRECISION;
      ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
      ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_out_time TIMESTAMP;
      ALTER TABLE attendance ADD COLUMN IF NOT EXISTS check_in_method VARCHAR(50);
      ALTER TABLE employees ADD COLUMN IF NOT EXISTS fcm_token TEXT;
      ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS is_recalled BOOLEAN DEFAULT FALSE;
      
      CREATE TABLE IF NOT EXISTS employee_banks (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        bank_name VARCHAR(255) NOT NULL,
        account_number VARCHAR(50) NOT NULL,
        account_holder VARCHAR(255) NOT NULL,
        is_default BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        department_ids JSONB DEFAULT '[]',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS user_notifications (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        type VARCHAR(50),
        data JSONB DEFAULT '{}',
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Khởi tạo cấu hình mặc định nếu chưa có
    const configCheck = await pool.query('SELECT COUNT(*) FROM company_config');
    if (parseInt(configCheck.rows[0].count) === 0) {
      await pool.query("INSERT INTO company_config (company_name) VALUES ('QUẬN 12')");
      console.log('✅ Đã tạo cấu hình công ty mặc định');
    }

    console.log("✅ Database đã được đồng bộ hóa thành công!");
  } catch (err) {
    console.error("❌ Lỗi đồng bộ Database:", err.message);
  }
};
initDB();


// Lưu trữ OTP tạm thời (Trong thực tế nên dùng Redis)
const otpStore = new Map();


// --- 0. API QUẢN LÝ LỊCH HỌP (MEETINGS) ---
app.get('/api/meetings', async (req, res) => {
  try {
    const r = await pool.query('SELECT * FROM meetings ORDER BY start_time DESC');
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/meetings', async (req, res) => {
  try {
    const { title, content, department_ids, start_time, location, is_online } = req.body;
    let meet_link = location;
    
    if (is_online && !location) {
      const letters = 'abcdefghijklmnopqrstuvwxyz';
      const gen = (len) => Array.from({length: len}, () => letters[Math.floor(Math.random() * letters.length)]).join('');
      meet_link = `https://meet.google.com/${gen(3)}-${gen(4)}-${gen(3)}`;
    }



    const result = await pool.query(
      'INSERT INTO meetings (title, content, department_ids, start_time, location, is_online) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [title, content, JSON.stringify(department_ids), start_time, meet_link, is_online]
    );

    // Lưu thông báo vào user_notifications cho tất cả nhân viên trong các phòng ban mục tiêu
    try {
      const depts = Array.isArray(department_ids) ? department_ids : [department_ids];
      if (depts.length > 0) {
        await pool.query(`
          INSERT INTO user_notifications (employee_id, title, body, type, data)
          SELECT id, $1, $2, 'meeting', $3
          FROM employees 
          WHERE department_id = ANY($4)
        `, [
          `📅 Lịch họp: ${title}`,
          `Nội dung: ${content || 'Không có nội dung'}\nThời gian: ${start_time}\nĐịa điểm: ${meet_link}`,
          JSON.stringify({ meeting_id: result.rows[0].id, start_time }),
          depts
        ]);
      }
    } catch (e) {
      console.error('❌ Lỗi lưu thông báo cuộc họp:', e.message);
    }

    io.emit('new_meeting', {
      meeting: result.rows[0],
      target_departments: department_ids
    });

    res.json({ success: true, meeting: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/meetings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content, department_ids, start_time, location, is_online } = req.body;
    await pool.query(
      'UPDATE meetings SET title=$1, content=$2, department_ids=$3, start_time=$4, location=$5, is_online=$6 WHERE id=$7',
      [title, content, JSON.stringify(department_ids), start_time, location, is_online, id]
    );
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/meetings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🗑️ Đang yêu cầu hủy cuộc họp ID: ${id}`);
    
    const meeting = await pool.query('SELECT * FROM meetings WHERE id=$1', [id]);
    if (meeting.rows.length > 0) {
      const m = meeting.rows[0];
      let deptIds = [];
      try {
        deptIds = Array.isArray(m.department_ids) ? m.department_ids : JSON.parse(m.department_ids || '[]');
      } catch (e) {
        console.error('❌ Lỗi parse department_ids:', m.department_ids);
        deptIds = [];
      }
      
      console.log('📢 Phát sự kiện meeting_canceled cho các phòng:', deptIds);
      io.emit('meeting_canceled', {
        meeting_id: id,
        title: m.title,
        target_departments: deptIds
      });
    }
    
    await pool.query('DELETE FROM meetings WHERE id=$1', [id]);
    console.log('✅ Đã xóa cuộc họp khỏi DB');
    res.json({ success: true });
  } catch (err) { 
    console.error('❌ Lỗi xóa cuộc họp:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

// --- 0.2 API THÔNG BÁO (NOTIFICATIONS) ---
app.get('/api/notifications', async (req, res) => {
  try {
    const r = await pool.query('SELECT * FROM notifications ORDER BY created_at DESC');
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/notifications', async (req, res) => {
  try {
    const { title, content, department_ids } = req.body;
    const result = await pool.query(
      'INSERT INTO notifications (title, content, department_ids) VALUES ($1, $2, $3) RETURNING *',
      [title, content, JSON.stringify(department_ids)]
    );
    io.emit('new_notification', {
      notification: result.rows[0],
      target_departments: department_ids
    });
    res.json({ success: true, notification: result.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/notifications/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM notifications WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- API ĐỒNG BỘ THÔNG BÁO ---
app.get('/api/notifications/sync', async (req, res) => {
  const { employee_id, department_id } = req.query;
  console.log(`🔄 Đồng bộ thông báo cho NV: ${employee_id}, PB: ${department_id}`);
  try {
    // 1. Lấy thông báo chung (từ bảng notifications)
    const generalNotifs = await pool.query(`
      SELECT 'announcement' as type, title, content as body, created_at, id as server_id
      FROM notifications 
      WHERE department_ids @> $1::jsonb OR department_ids = '[]'::jsonb
      ORDER BY created_at DESC LIMIT 50
    `, [JSON.stringify([Number(department_id)])]);

    // 2. Lấy thông báo cá nhân (từ bảng user_notifications)
    const userNotifs = await pool.query(`
      SELECT type, title, body, created_at, id as server_id, data
      FROM user_notifications 
      WHERE employee_id = $1
      ORDER BY created_at DESC LIMIT 50
    `, [employee_id]);

    // Gộp và sắp xếp
    const all = [...generalNotifs.rows, ...userNotifs.rows].sort((a, b) => 
      new Date(b.created_at) - new Date(a.created_at)
    );

    res.json(all);
  } catch (err) {
    console.error('❌ Lỗi đồng bộ thông báo:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// --- 1. API HỆ THỐNG & AUTH ---
app.post('/api/auth/send-otp', async (req, res) => {
  const { employee_id } = req.body;
  try {
    const user = await pool.query('SELECT email FROM employees WHERE id = $1', [employee_id]);
    if (user.rows.length === 0) return res.status(404).json({ message: "Không tìm thấy người dùng" });

    const email = user.rows[0].email;
    console.log(`📧 Đang gửi OTP đến email: ${email}`);
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Lưu OTP trong 5 phút
    otpStore.set(employee_id.toString(), {
      otp,
      expires: Date.now() + 5 * 60 * 1000
    });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: '[WorkMate] Mã xác thực OTP thay đổi mật khẩu',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2>Xác thực thay đổi mật khẩu</h2>
          <p>Chào bạn,</p>
          <p>Mã OTP của bạn là: <b style="font-size: 24px; color: #007bff;">${otp}</b></p>
          <p>Mã này có hiệu lực trong 5 phút. Vui lòng không chia sẻ mã này với bất kỳ ai.</p>
          <hr/>
          <p style="font-size: 12px; color: #777;">Đây là email tự động từ hệ thống WorkMate.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log(`✅ Đã gửi OTP thành công đến ${email}`);
    res.json({ success: true, message: "OTP đã được gửi thành công" });
  } catch (err) {
    console.error('❌ Lỗi gửi OTP CHI TIẾT:', err);
    res.status(500).json({ error: err.message || "Không thể gửi email" });
  }
});

app.post('/api/auth/change-password', async (req, res) => {
  const { employee_id, new_password, otp } = req.body;
  try {
    // Verify OTP
    const stored = otpStore.get(employee_id.toString());
    if (!stored || stored.otp !== otp || Date.now() > stored.expires) {
      return res.status(400).json({ message: "Mã OTP không hợp lệ hoặc đã hết hạn" });
    }

    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(new_password, salt);
    
    await pool.query('UPDATE employees SET password_hash = $1 WHERE id = $2', [hash, employee_id]);
    otpStore.delete(employee_id.toString()); // Xóa OTP sau khi dùng
    
    res.json({ success: true, message: "Đổi mật khẩu thành công" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await pool.query('SELECT id, name FROM employees WHERE email = $1', [email]);
    if (user.rows.length === 0) return res.status(404).json({ message: "Email không tồn tại trong hệ thống" });

    const newPassword = Math.random().toString(36).slice(-8);
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(newPassword, salt);
    
    await pool.query('UPDATE employees SET password_hash = $1 WHERE email = $2', [hash, email]);

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: '[WorkMate] Khôi phục mật khẩu tài khoản',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2>Khôi phục mật khẩu</h2>
          <p>Chào ${user.rows[0].name},</p>
          <p>Mật khẩu mới của bạn đã được khởi tạo lại là: <b style="font-size: 18px; color: #dc3545;">${newPassword}</b></p>
          <p>Vui lòng đăng nhập lại bằng mật khẩu này và thay đổi mật khẩu ngay để đảm bảo an toàn.</p>
          <hr/>
          <p style="font-size: 12px; color: #777;">Đây là email tự động từ hệ thống WorkMate.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: "Mật khẩu mới đã được gửi vào email" });
  } catch (err) {
    console.error('❌ Lỗi quên mật khẩu:', err);
    res.status(500).json({ error: "Lỗi hệ thống" });
  }
});

app.post('/api/auth/login', async (req, res) => {
  console.log('🔑 Yêu cầu đăng nhập:', req.body);
  try {
    let { code, email, password } = req.body;
    const loginIdentifier = (email || code || '').trim();
    
    if (!loginIdentifier) return res.status(400).json({ message: "Vui lòng nhập tài khoản" });

    const r = await pool.query(
      'SELECT * FROM employees WHERE employee_code = $1 OR email = $1', 
      [loginIdentifier]
    );
    
    if (r.rows.length === 0) {
      console.log(`❌ Không tìm thấy user với định danh: ${loginIdentifier}`);
      return res.status(404).json({ message: "Không tìm thấy người dùng" });
    }
    
    const user = r.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    
    if (!valid) {
      console.log(`❌ Sai mật khẩu cho user: ${user.email}`);
      return res.status(401).json({ message: "Sai mật khẩu" });
    }
    
    console.log(`✅ Đăng nhập thành công: ${user.name}`);
    
    // Xóa password_hash trước khi gửi về client
    const loggedInUser = { ...r.rows[0] };
    delete loggedInUser.password_hash;
    
    res.json({ user: loggedInUser });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- 2. FACE ID ROUTES ---
app.post('/api/face/register', async (req, res) => {
  const { employee_id, embeddings } = req.body;
  try {
    // Nếu client gửi 1 embedding (bản cũ) thì đưa vào mảng
    const embs = Array.isArray(embeddings) && embeddings.length > 0 && Array.isArray(embeddings[0]) 
      ? embeddings 
      : (req.body.embedding ? [req.body.embedding] : []);
      
    if (embs.length === 0) {
      return res.status(400).json({ success: false, message: "Không có dữ liệu khuôn mặt" });
    }

    // Xóa dữ liệu cũ
    await pool.query('DELETE FROM face_embeddings WHERE employee_id = $1', [employee_id]);
    
    // Lưu các góc mặt mới
    const angles = ['center', 'left', 'right', 'up', 'down'];
    for (let i = 0; i < embs.length; i++) {
      await pool.query(
        'INSERT INTO face_embeddings (employee_id, embedding, angle) VALUES ($1, $2, $3)',
        [employee_id, JSON.stringify(embs[i]), angles[i] || 'unknown']
      );
    }
    
    // Đánh dấu đã đăng ký trong bảng employees
    await pool.query('UPDATE employees SET face_registered_at = NOW() WHERE id = $1', [employee_id]);

    res.json({ success: true, message: "Đăng ký thành công" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.get('/api/face/embedding/:id', async (req, res) => {
  try {
    const r = await pool.query('SELECT embedding FROM face_embeddings WHERE employee_id = $1', [req.params.id]);
    if (r.rows.length === 0) return res.status(404).json({ message: "Chưa có dữ liệu" });
    
    // Trả về danh sách embeddings
    const embeddings = r.rows.map(row => typeof row.embedding === 'string' ? JSON.parse(row.embedding) : row.embedding);
    // Để tương thích ngược với client cũ, trả về embedding đầu tiên (nhưng client mới sẽ dùng mảng)
    res.json({ success: true, embedding: embeddings[0], embeddings: embeddings });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- HELPER: Haversine Distance (GPS) ---
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // metres
  const φ1 = lat1 * Math.PI/180;
  const φ2 = lat2 * Math.PI/180;
  const Δφ = (lat2-lat1) * Math.PI/180;
  const Δλ = (lon2-lon1) * Math.PI/180;
  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
          Math.cos(φ1) * Math.cos(φ2) *
          Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c; // in metres
}

app.post('/api/face/checkin', async (req, res) => {
  const { employee_id, embedding, lat, lng, wifi_ssid, action } = req.body;
  console.log(`📥 Nhận yêu cầu ${action} cho nhân viên ID: ${employee_id}`);
  
  try {
    // 1. Lấy cấu hình Safe Zone
    const configResult = await pool.query('SELECT * FROM company_config LIMIT 1');
    const config = configResult.rows[0];

    // 2. Kiểm tra WiFi
    if (config && config.safe_wifi_ssid && wifi_ssid !== config.safe_wifi_ssid) {
      return res.status(403).json({ success: false, message: `Vui lòng kết nối WiFi: ${config.safe_wifi_ssid}` });
    }

    // 3. Kiểm tra GPS
    if (config && config.safe_lat && config.safe_lng) {
      const distance = getDistance(lat, lng, config.safe_lat, config.safe_lng);
      if (distance > config.radius_meters) {
        return res.status(403).json({ success: false, message: `Bạn đang ở ngoài vùng cho phép (${Math.round(distance)}m)` });
      }
    }

    // 4. Kiểm tra khuôn mặt
    const r = await pool.query('SELECT embedding FROM face_embeddings WHERE employee_id = $1', [employee_id]);
    

    if (r.rows.length === 0) return res.status(400).json({ message: "Chưa đăng ký khuôn mặt" });
    
    let maxSimilarity = -1;
    for (let row of r.rows) {
      const saved = typeof row.embedding === 'string' ? JSON.parse(row.embedding) : row.embedding;
      const sim = cosineSimilarity(embedding, saved);
      if (sim > maxSimilarity) maxSimilarity = sim;
    }
    
    if (maxSimilarity < MATCH_THRESHOLD) {
      return res.status(403).json({ success: false, message: "Khuôn mặt không khớp" });
    }

    // 5. Xử lý logic Chấm công theo ACTION
    const existing = await pool.query(
      "SELECT * FROM attendance WHERE employee_id = $1 AND DATE(check_in_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::DATE", 
      [employee_id]
    );

    if (action === 'check_in') {
      if (existing.rows.length > 0) {
        return res.status(400).json({ success: false, message: "Bạn đã check-in hôm nay rồi" });
      }
      const result = await pool.query(
        "INSERT INTO attendance (employee_id, check_in_time, check_in_method) VALUES ($1, NOW(), 'FACE_ID') RETURNING *", 
        [employee_id]
      );
      io.emit('new_attendance', result.rows[0]);
    } else if (action === 'check_out') {
      if (existing.rows.length === 0) {
        return res.status(400).json({ success: false, message: "Bạn chưa check-in hôm nay" });
      }
      if (existing.rows[0].check_out_time) {
        return res.status(400).json({ success: false, message: "Bạn đã check-out hôm nay rồi" });
      }

      // Ngăn chặn check-out quá nhanh (dưới 1 phút)
      const checkInTime = new Date(existing.rows[0].check_in_time);
      const now = new Date();
      if (now - checkInTime < 60000) { // 1 phút
        return res.status(400).json({ success: false, message: "Vui lòng đợi ít nhất 1 phút sau khi check-in" });
      }

      const result = await pool.query(
        "UPDATE attendance SET check_out_time = NOW() WHERE id = $1 RETURNING *", 
        [existing.rows[0].id]
      );
      io.emit('attendance_updated', result.rows[0]);
    }

    res.json({ success: true, message: "Thao tác thành công" });
  } catch (err) {
    console.error('🔥 LỖI:', err);
    res.status(500).json({ message: err.message });
  }
});

// --- 1.2 API UPLOAD FILE ---
app.post('/api/upload', upload.single('file'), (req, res) => {
  console.log('📥 Nhận yêu cầu upload file:', req.file?.originalname);
  if (!req.file) {
    console.log('❌ Không tìm thấy file trong request');
    return res.status(400).json({ message: "Không có file nào được tải lên" });
  }
  const fileUrl = `/uploads/${req.file.filename}`;
  console.log('✅ Upload thành công:', fileUrl);
  res.json({ success: true, url: fileUrl });
});

app.post('/api/employees/avatar', async (req, res) => {
  const { employee_id, avatar_url } = req.body;
  try {
    await pool.query('UPDATE employees SET avatar_url = $1 WHERE id = $2', [avatar_url, employee_id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- 1.5. API CẤU HÌNH HỆ THỐNG (CONFIG) ---
// Hỗ trợ cả 2 endpoint để tương thích với Frontend
const getConfig = async (req, res) => {
  try {
    const r = await pool.query('SELECT * FROM company_config LIMIT 1');
    res.json(r.rows[0] || { company_name: 'WorkMate HQ' });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

const postConfig = async (req, res) => {
  const { 
    company_name, safe_lat, safe_lng, safe_wifi_ssid, safe_wifi_bssid, radius_meters,
    work_start_time, work_end_time, break_start_time, break_end_time, work_days
  } = req.body;
  console.log('📥 Nhận yêu cầu cập nhật cấu hình:', { company_name, work_days });
  try {
    const existing = await pool.query('SELECT id FROM company_config LIMIT 1');
    if (existing.rows.length > 0) {
      const r = await pool.query(
        `UPDATE company_config SET 
          company_name = $1, safe_lat = $2, safe_lng = $3, 
          safe_wifi_ssid = $4, safe_wifi_bssid = $5, radius_meters = $6,
          work_start_time = $7, work_end_time = $8, 
          break_start_time = $9, break_end_time = $10, 
          work_days = $11
         WHERE id = $12 RETURNING *`,
        [
          company_name, safe_lat, safe_lng, 
          safe_wifi_ssid, safe_wifi_bssid, radius_meters,
          work_start_time, work_end_time, 
          break_start_time, break_end_time, 
          typeof work_days === 'string' ? work_days : JSON.stringify(work_days),
          existing.rows[0].id
        ]
      );
      res.json(r.rows[0]);
    } else {
      const r = await pool.query(
        `INSERT INTO company_config (
          company_name, safe_lat, safe_lng, 
          safe_wifi_ssid, safe_wifi_bssid, radius_meters,
          work_start_time, work_end_time, 
          break_start_time, break_end_time, work_days
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
        [
          company_name, safe_lat, safe_lng, 
          safe_wifi_ssid, safe_wifi_bssid, radius_meters,
          work_start_time, work_end_time, 
          break_start_time, break_end_time,
          typeof work_days === 'string' ? work_days : JSON.stringify(work_days)
        ]
      );
      res.json(r.rows[0]);
    }
  } catch (err) { res.status(500).json({ error: err.message }); }
};

app.get('/api/config', getConfig);
app.get('/api/company/config', getConfig);
app.post('/api/config', postConfig);
app.post('/api/company/config', postConfig);

app.delete('/api/system/clear', async (req, res) => {
  await pool.query('TRUNCATE attendance, approvals, meetings, employees, departments RESTART IDENTITY CASCADE');
  res.json({ message: "Đã xóa sạch dữ liệu hệ thống" });
});

// --- 2. API QUẢN LÝ PHÒNG BAN (DEPARTMENTS) ---
app.get('/api/departments', async (req, res) => {
  try {
    const r = await pool.query('SELECT * FROM departments ORDER BY name ASC');
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/departments', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { name, code, positions } = req.body;
    const r = await client.query(
      'INSERT INTO departments (name, code, positions) VALUES ($1, $2, $3) RETURNING *',
      [name, code, positions]
    );
    const newDept = r.rows[0];

    // Tạo group chat
    const groupName = `Phòng ${name}`;
    const chatRes = await client.query(
      `INSERT INTO conversations (type, name, created_by) VALUES ('group', $1, 1) RETURNING id`,
      [groupName]
    );
    const chatId = chatRes.rows[0].id;

    // Cập nhật group_chat_id
    await client.query('UPDATE departments SET group_chat_id = $1 WHERE id = $2', [chatId, newDept.id]);
    newDept.group_chat_id = chatId;

    await client.query('COMMIT');
    res.json(newDept);
  } catch (err) { 
    await client.query('ROLLBACK');
    res.status(500).json({ error: err.message }); 
  } finally {
    client.release();
  }
});

app.put('/api/departments/:id', async (req, res) => {
  try {
    const { name, code, positions } = req.body;
    const r = await pool.query(
      'UPDATE departments SET name = $1, code = $2, positions = $3 WHERE id = $4 RETURNING *',
      [name, code, positions, req.params.id]
    );
    res.json(r.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/departments/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM departments WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- 3. API QUẢN LÝ NHÂN VIÊN (EMPLOYEES) ---
app.get('/api/employees', async (req, res) => {
  try {
    const r = await pool.query('SELECT * FROM employees ORDER BY created_at DESC');
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/employees/code/:code', async (req, res) => {
  try {
    const { code } = req.params;
    const r = await pool.query('SELECT * FROM employees WHERE employee_code = $1', [code]);
    if (r.rows.length === 0) return res.status(404).json({ error: 'Không tìm thấy nhân viên' });
    res.json(r.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/employees', async (req, res) => {
  try {
    const { name, email, phone, department_id, position, join_date, birthday } = req.body;
    
    // 1. Lấy thông tin phòng ban
    const deptResult = await pool.query('SELECT name, code FROM departments WHERE id = $1', [department_id]);
    if (deptResult.rows.length === 0) return res.status(400).json({ error: 'Phòng ban không tồn tại' });
    
    const dept = deptResult.rows[0];
    const deptCode = dept.code || 'NV';
    const year = new Date(join_date).getFullYear().toString().slice(-2);
    const random = Math.floor(1000 + Math.random() * 9000);
    const employee_code = `${deptCode}${year}${random}`;
    
    // 2. Tạo mật khẩu ngẫu nhiên (8 ký tự)
    const password = Math.random().toString(36).slice(-8);
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    // 3. Lưu vào DB
    const result = await pool.query(
      'INSERT INTO employees (employee_code, name, email, password_hash, phone, department_id, department_name, position, join_date, birthday) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *',
      [employee_code, name, email, password_hash, phone, department_id, dept.name, position, join_date, birthday]
    );

    const newEmp = result.rows[0];

    // Thêm vào group chat phòng ban
    const deptInfoRes = await pool.query('SELECT group_chat_id FROM departments WHERE id = $1', [department_id]);
    if (deptInfoRes.rows.length > 0 && deptInfoRes.rows[0].group_chat_id) {
      await pool.query('INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)', [deptInfoRes.rows[0].group_chat_id, newEmp.id]);
    }

    console.log(`✨ Đã tạo nhân viên mới: ${employee_code}`);

    // 4. Gửi Email thông báo (Chạy ngầm)
    const mailOptions = {
      from: `"WorkMate System" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Chào mừng bạn đến với WorkMate - Thông tin tài khoản của bạn',
      html: `
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden;">
          <div style="background-color: #1C6185; padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px;">Chào mừng bạn đến với WorkMate!</h1>
          </div>
          <div style="padding: 40px; background-color: white; line-height: 1.6; color: #334155;">
            <p>Xin chào <strong>${name}</strong>,</p>
            <p>Chào mừng bạn đã gia nhập đội ngũ của chúng tôi. Tài khoản nhân viên của bạn đã được tạo thành công trên hệ thống <strong>WorkMate</strong>.</p>
            <p>Dưới đây là thông tin đăng nhập của bạn:</p>
            <div style="background-color: #f1f5f9; padding: 20px; border-radius: 8px; margin: 25px 0;">
              <p style="margin: 0 0 10px 0;"><strong>Mã nhân viên:</strong> <span style="color: #1C6185; font-weight: bold; font-size: 18px;">${employee_code}</span></p>
              <p style="margin: 0;"><strong>Mật khẩu tạm thời:</strong> <span style="color: #1C6185; font-weight: bold; font-size: 18px;">${password}</span></p>
            </div>
            <p style="color: #64748b; font-size: 14px;"><em>* Vui lòng đổi mật khẩu ngay sau khi đăng nhập lần đầu để đảm bảo an toàn cho tài khoản của bạn.</em></p>
            <div style="text-align: center; margin-top: 35px;">
              <a href="#" style="background-color: #1C6185; color: white; padding: 14px 30px; text-decoration: none; border-radius: 30px; font-weight: bold; display: inline-block;">TẢI ỨNG DỤNG NGAY</a>
            </div>
          </div>
          <div style="background-color: #f8fafc; padding: 20px; text-align: center; color: #94a3b8; font-size: 12px; border-top: 1px solid #e2e8f0;">
            <p style="margin: 0;">© 2025 WorkMate Ecosystem. All rights reserved.</p>
          </div>
        </div>
      `
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error('❌ Lỗi gửi email:', error);
      } else {
        console.log('📧 Đã gửi email thông tin tài khoản tới:', email);
      }
    });

    res.json({ ...result.rows[0], password }); 
  } catch (err) { 
    console.error('❌ Lỗi tạo nhân viên:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

app.put('/api/employees/:id', async (req, res) => {
  try {
    const { name, email, phone, department_id, position, join_date, birthday } = req.body;
    console.log(`📝 Cập nhật nhân viên ${req.params.id}:`, { name, email, phone, birthday });

    // Lấy tên phòng ban mới nếu có thay đổi
    const deptResult = await pool.query('SELECT name FROM departments WHERE id = $1', [department_id]);
    const deptName = deptResult.rows[0]?.name || '';

    const result = await pool.query(
      'UPDATE employees SET name = $1, email = $2, phone = $3, department_id = $4, department_name = $5, position = $6, join_date = $7, birthday = $8 WHERE id = $9 RETURNING *',
      [name, email, phone, department_id, deptName, position, join_date || null, birthday || null, req.params.id]
    );

    console.log(`✅ Đã cập nhật nhân viên: ${result.rows[0].employee_code}`);
    res.json(result.rows[0]);
  } catch (err) { 
    console.error('❌ Lỗi cập nhật nhân viên:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

app.delete('/api/employees/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM employees WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- 4. API TÀI KHOẢN NGÂN HÀNG (EMPLOYEE BANKS) ---
app.get('/api/employees/:id/banks', async (req, res) => {
  try {
    const r = await pool.query('SELECT * FROM employee_banks WHERE employee_id = $1 ORDER BY is_default DESC, created_at DESC', [req.params.id]);
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/employees/:id/banks', async (req, res) => {
  try {
    const { id } = req.params;
    const { bank_name, account_number, account_holder } = req.body;

    // Giới hạn tối đa 3 thẻ
    const countRes = await pool.query('SELECT COUNT(*) FROM employee_banks WHERE employee_id = $1', [id]);
    if (parseInt(countRes.rows[0].count) >= 3) {
      return res.status(400).json({ error: 'Chỉ có thể thêm tối đa 3 tài khoản ngân hàng' });
    }

    const r = await pool.query(
      'INSERT INTO employee_banks (employee_id, bank_name, account_number, account_holder) VALUES ($1, $2, $3, $4) RETURNING *',
      [id, bank_name, account_number, account_holder.toUpperCase()]
    );
    res.json(r.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/employees/banks/:bankId', async (req, res) => {
  try {
    const { bankId } = req.params;
    const { bank_name, account_number, account_holder, is_default } = req.body;
    const r = await pool.query(
      'UPDATE employee_banks SET bank_name = $1, account_number = $2, account_holder = $3, is_default = $4 WHERE id = $5 RETURNING *',
      [bank_name, account_number, account_holder.toUpperCase(), is_default, bankId]
    );
    res.json(r.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/employees/banks/:bankId', async (req, res) => {
  try {
    await pool.query('DELETE FROM employee_banks WHERE id = $1', [req.params.bankId]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- API FIREBASE TOKEN ---
app.post('/api/employees/fcm-token', async (req, res) => {
  try {
    const { employee_id, token } = req.body;
    await pool.query('UPDATE employees SET fcm_token = $1 WHERE id = $2', [token, employee_id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Helper tính toán giờ công theo quy định
function calculateWorkingHours(checkIn, checkOut, config, approvedOT = 0) {
  if (!checkIn || !checkOut) return { total: 0, normal: 0, ot: 0 };

  const start = new Date(checkIn);
  const end = new Date(checkOut);
  const dateStr = start.toISOString().split('T')[0];

  // Chuyển đổi cấu hình giờ sang Date object cho ngày hiện tại
  const workStart = new Date(`${dateStr}T${config.work_start_time || '08:00'}:00`);
  const workEnd = new Date(`${dateStr}T${config.work_end_time || '17:00'}:00`);
  const breakStart = new Date(`${dateStr}T${config.break_start_time || '12:00'}:00`);
  const breakEnd = new Date(`${dateStr}T${config.break_end_time || '13:00'}:00`);

  // 1. Tính giờ hành chính (chỉ nằm trong khoảng workStart -> workEnd)
  const effectiveStart = start > workStart ? start : workStart;
  const effectiveEnd = end < workEnd ? end : workEnd;
  
  let normalMs = 0;
  if (effectiveEnd > effectiveStart) {
    normalMs = effectiveEnd - effectiveStart;
    
    // Trừ giờ nghỉ trưa nếu có giao thoa
    const overlapBreakStart = effectiveStart > breakStart ? effectiveStart : breakStart;
    const overlapBreakEnd = effectiveEnd < breakEnd ? effectiveEnd : breakEnd;
    if (overlapBreakEnd > overlapBreakStart) {
      normalMs -= (overlapBreakEnd - overlapBreakStart);
    }
  }

  // 2. Tính giờ OT (nếu có check out sau workEnd và có approvedOT)
  let otMs = 0;
  if (end > workEnd && approvedOT > 0) {
    const actualOTMs = end - workEnd;
    const allowedOTMs = approvedOT * 60 * 60 * 1000;
    otMs = actualOTMs > allowedOTMs ? allowedOTMs : actualOTMs;
  }

  const normal = normalMs / (1000 * 60 * 60);
  const ot = otMs / (1000 * 60 * 60);

  return {
    total: parseFloat((normal + ot).toFixed(2)),
    normal: parseFloat(normal.toFixed(2)),
    ot: parseFloat(ot.toFixed(2))
  };
}


// Helper gửi thông báo
async function sendPushNotification(employeeId, title, body, data = {}) {
  try {
    const r = await pool.query('SELECT fcm_token FROM employees WHERE id = $1', [employeeId]);
    const token = r.rows[0]?.fcm_token;
    if (!token) return;

    const message = {
      notification: { title, body },
      data: { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
      token: token
    };

    await admin.messaging().send(message);
    console.log(`🚀 Đã gửi Push Notification tới ID ${employeeId}`);
  } catch (err) {
    console.error('❌ Lỗi gửi Push Notification:', err.message);
  }
}


// --- 4. API QUẢN LÝ LỊCH HỌP (MEETINGS) ---

// API Xuất Excel
app.get('/api/attendance/export', async (req, res) => {
  try {
    const { month } = req.query; // YYYY-MM
    const r = await pool.query(`
      SELECT a.*, e.name as employee_name, e.employee_code,
             to_char(a.check_in_time, 'YYYY-MM-DD') as date,
             to_char(a.check_in_time, 'HH24:MI:SS') as check_in,
             to_char(a.check_out_time, 'HH24:MI:SS') as check_out
      FROM attendance a
      JOIN employees e ON a.employee_id = e.id
      WHERE to_char(a.check_in_time, 'YYYY-MM') = $1
      ORDER BY e.name, a.check_in_time
    `, [month]);

    const configRes = await pool.query('SELECT * FROM company_config LIMIT 1');
    const config = configRes.rows[0];

    const otRes = await pool.query(`
      SELECT employee_id, to_char(from_date, 'YYYY-MM-DD') as date, SUM(total_hours) as hours
      FROM approvals 
      WHERE status = 'approved' AND type = 'Làm thêm giờ'
      GROUP BY employee_id, to_char(from_date, 'YYYY-MM-DD')
    `);
    const otMap = {};
    otRes.rows.forEach(row => {
      otMap[`${row.employee_id}_${row.date}`] = parseFloat(row.hours);
    });

    const banksRes = await pool.query('SELECT * FROM employee_banks ORDER BY is_default DESC, created_at DESC');
    const bankMap = {};
    banksRes.rows.forEach(row => {
      if (!bankMap[row.employee_id]) {
        bankMap[row.employee_id] = row;
      }
    });

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Báo cáo Chi tiết');
    const summarySheet = workbook.addWorksheet('Tổng hợp Công');

    // Sheet 1: Chi tiết
    worksheet.columns = [
      { header: 'Mã NV', key: 'code', width: 15 },
      { header: 'Họ tên', key: 'name', width: 25 },
      { header: 'Ngày', key: 'date', width: 15 },
      { header: 'Giờ vào', key: 'in', width: 12 },
      { header: 'Giờ ra', key: 'out', width: 12 },
      { header: 'Tổng giờ', key: 'total', width: 12 },
      { header: 'Giờ hành chính', key: 'normal', width: 15 },
      { header: 'Giờ OT', key: 'ot', width: 12 }
    ];
    worksheet.getRow(1).font = { bold: true };

    // Sheet 2: Tổng hợp
    summarySheet.columns = [
      { header: 'Mã NV', key: 'code', width: 15 },
      { header: 'Họ tên', key: 'name', width: 25 },
      { header: 'Tổng giờ làm', key: 'totalHours', width: 15 },
      { header: 'Ngân hàng', key: 'bank_name', width: 20 },
      { header: 'Số tài khoản', key: 'account_number', width: 20 },
      { header: 'Chủ tài khoản', key: 'account_holder', width: 25 }
    ];
    summarySheet.getRow(1).font = { bold: true };

    const summaryMap = {}; // employee_code -> { name, total }

    r.rows.forEach(row => {
      const approvedOT = otMap[`${row.employee_id}_${row.date}`] || 0;
      const hours = calculateWorkingHours(row.check_in_time, row.check_out_time, config, approvedOT);
      
      worksheet.addRow({
        code: row.employee_code,
        name: row.employee_name,
        date: row.date,
        in: row.check_in,
        out: row.check_out || '--:--:--',
        total: hours.total,
        normal: hours.normal,
        ot: hours.ot
      });

      if (!summaryMap[row.employee_code]) {
        const bank = bankMap[row.employee_id] || {};
        summaryMap[row.employee_code] = { 
          name: row.employee_name, 
          total: 0,
          bank_name: bank.bank_name || '',
          account_number: bank.account_number || '',
          account_holder: bank.account_holder || ''
        };
      }
      summaryMap[row.employee_code].total += hours.total;
    });

    Object.keys(summaryMap).forEach(code => {
      summarySheet.addRow({
        code: code,
        name: summaryMap[code].name,
        totalHours: parseFloat(summaryMap[code].total.toFixed(2)),
        bank_name: summaryMap[code].bank_name,
        account_number: summaryMap[code].account_number,
        account_holder: summaryMap[code].account_holder
      });
    });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=Bao_cao_cham_cong_${month}.xlsx`);
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/attendance', async (req, res) => {
  try {
    const { date } = req.query;
    let query = `
      SELECT a.*, e.name as employee_name, e.employee_code,
             a.check_in_method as method,
             to_char(a.check_in_time, 'YYYY-MM-DD') as date,
             to_char(a.check_in_time, 'HH24:MI:SS') as check_in,
             to_char(a.check_out_time, 'HH24:MI:SS') as check_out
      FROM attendance a
      JOIN employees e ON a.employee_id = e.id
    `;
    let params = [];
    
    if (date) {
      query += ` WHERE to_char(a.check_in_time, 'YYYY-MM-DD') = $1`;
      params.push(date);
    }
    
    query += ` ORDER BY a.check_in_time DESC`;
    
    const r = await pool.query(query, params);
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/attendance/today/:employee_id', async (req, res) => {
  try {
    const { employee_id } = req.params;
    const r = await pool.query(
      "SELECT * FROM attendance WHERE employee_id = $1 AND DATE(check_in_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::DATE ORDER BY check_in_time DESC LIMIT 1",
      [employee_id]
    );
    res.json(r.rows[0] || null);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/attendance/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { check_in, check_out, date } = req.body; // check_in/out format HH:mm:ss

    // 1. Lấy dữ liệu cũ để so sánh
    const oldRes = await pool.query(`
      SELECT a.*, to_char(check_in_time, 'HH24:MI:SS') as old_in, 
             to_char(check_out_time, 'HH24:MI:SS') as old_out
      FROM attendance a WHERE id = $1
    `, [id]);
    
    if (oldRes.rows.length === 0) return res.status(404).json({ error: 'Không tìm thấy bản ghi' });
    const old = oldRes.rows[0];

    // 2. Cập nhật vào DB
    // Lưu ý: check_in_time và check_out_time là TIMESTAMP, cần kết hợp với date
    const newIn = `${date} ${check_in}`;
    const newOut = check_out ? `${date} ${check_out}` : null;

    await pool.query(
      'UPDATE attendance SET check_in_time = $1, check_out_time = $2 WHERE id = $3',
      [newIn, newOut, id]
    );

    // 3. Gửi Push Notification thông báo thay đổi
    let changeLog = [];
    if (old.old_in !== check_in) changeLog.push(`Giờ vào: ${old.old_in} ➔ ${check_in}`);
    if ((old.old_out || '--:--:--') !== (check_out || '--:--:--')) {
      changeLog.push(`Giờ ra: ${old.old_out || '--:--:--'} ➔ ${check_out || '--:--:--'}`);
    }

    if (changeLog.length > 0) {
      const title = '⚡ Chỉnh sửa giờ công';
      const body = `Admin đã sửa giờ công ngày ${date}:\n${changeLog.join('\n')}`;
      
      await sendPushNotification(
        old.employee_id,
        title,
        body,
        { type: 'attendance_update', date }
      );

      // Emit realtime event để lưu vào danh sách thông báo trên App
      io.emit('attendance_edited', {
        employee_id: old.employee_id,
        title: title,
        body: body,
        date: date
      });

      // Lưu vào user_notifications
      await pool.query(
        "INSERT INTO user_notifications (employee_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5)",
        [old.employee_id, title, body, 'attendance_update', JSON.stringify({ date })]
      );
    }

    res.json({ success: true });
  } catch (err) { 
    console.error('❌ Lỗi sửa attendance:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

// --- 6. API PHÊ DUYỆT (APPROVALS) ---
app.post('/api/approvals', async (req, res) => {
  try {
    const { employee_id, employee_name, type, reason, from_date, to_date, attachment_urls, is_half_day, total_hours } = req.body;
    const result = await pool.query(
      'INSERT INTO approvals (employee_id, employee_name, type, reason, from_date, to_date, attachment_urls, is_half_day, total_hours, status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, \'pending\') RETURNING *',
      [employee_id, employee_name, type, reason, from_date, to_date, JSON.stringify(attachment_urls), is_half_day, total_hours]
    );
    io.emit('new_approval', result.rows[0]);
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/approvals/admin-assign', async (req, res) => {
  console.log('📝 Admin gán lịch OT/Nghỉ:', req.body);
  try {
    const { type, reason, from_date, to_date, total_hours, is_half_day, department_id, employee_ids } = req.body;
    
    let targetEmployees = [];
    
    if (department_id === 'all') {
      const r = await pool.query('SELECT id, name FROM employees');
      targetEmployees = r.rows;
    } else if (department_id) {
      const r = await pool.query('SELECT id, name FROM employees WHERE department_id = $1', [department_id]);
      targetEmployees = r.rows;
    } else if (employee_ids && employee_ids.length > 0) {
      const r = await pool.query('SELECT id, name FROM employees WHERE id = ANY($1)', [employee_ids]);
      targetEmployees = r.rows;
    } else {
      return res.status(400).json({ error: "Vui lòng chọn đối tượng gán" });
    }

    if (targetEmployees.length === 0) {
      return res.status(404).json({ error: "Không tìm thấy nhân viên phù hợp" });
    }

    for (const emp of targetEmployees) {
      const result = await pool.query(
        'INSERT INTO approvals (employee_id, employee_name, type, reason, from_date, to_date, total_hours, is_half_day, status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, \'approved\') RETURNING *',
        [emp.id, emp.name, type, reason, from_date, to_date, total_hours, is_half_day]
      );
      const approval = result.rows[0];
      
      // Notify
      io.emit(`receive_approval_${emp.id}`, approval);
      io.emit('new_approval', approval);
      
      await sendPushNotification(
        emp.id,
        `Lịch ${type} mới`,
        `Quản trị viên đã xếp lịch ${type} cho bạn: ${reason}`,
        { type: 'approval_assigned', id: approval.id.toString() }
      );
    }

    res.json({ success: true, message: `Đã gán lịch cho ${targetEmployees.length} nhân viên` });
  } catch (err) {
    console.error('❌ Lỗi admin-assign:', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/approvals', async (req, res) => {
  console.log('🔍 Truy vấn danh sách phê duyệt:', req.query);
  try {
    const { employee_id } = req.query;
    let query = 'SELECT * FROM approvals';
    let params = [];
    
    if (employee_id) {
      query += ' WHERE employee_id = $1';
      params.push(employee_id);
    }
    
    const r = await pool.query(query, params);
    
    // Chuẩn hóa dữ liệu trước khi gửi về
    const rows = r.rows.map(row => ({
      ...row,
      from_date: row.from_date ? new Date(row.from_date).toISOString() : null,
      to_date: row.to_date ? new Date(row.to_date).toISOString() : null,
      created_at: row.created_at ? new Date(row.created_at).toISOString() : null,
      reviewed_at: row.reviewed_at ? new Date(row.reviewed_at).toISOString() : null,
      attachment_urls: typeof row.attachment_urls === 'string' ? JSON.parse(row.attachment_urls) : (row.attachment_urls || [])
    }));

    console.log(`✅ Trả về ${rows.length} yêu cầu cho ID: ${employee_id || 'ALL'}`);
    res.json(rows);
  } catch (err) { 
    console.error('❌ Lỗi truy vấn approvals:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

app.put('/api/approvals/:id', async (req, res) => {
  try {
    const { status } = req.body;
    // 1. Cập nhật trạng thái phê duyệt
    const result = await pool.query('UPDATE approvals SET status = $1 WHERE id = $2 RETURNING *', [status, req.params.id]);
    const approval = result.rows[0];
    
    // 2. Nếu là Quên chấm công và được duyệt -> Thêm vào bảng attendance NGAY LẬP TỨC
    if (status === 'approved' && approval.type === 'Quên chấm công') {
      console.log('📝 Bổ sung chấm công từ đơn quên chấm công cho:', approval.employee_name);
      try {
        const checkIn = new Date(approval.from_date);
        const checkOut = new Date(approval.to_date);
        
        // Định dạng HH:mm:ss cho các cột varchar nếu cần
        const cinStr = `${checkIn.getHours().toString().padStart(2, '0')}:${checkIn.getMinutes().toString().padStart(2, '0')}:${checkIn.getSeconds().toString().padStart(2, '0')}`;
        const coutStr = `${checkOut.getHours().toString().padStart(2, '0')}:${checkOut.getMinutes().toString().padStart(2, '0')}:${checkOut.getSeconds().toString().padStart(2, '0')}`;

        await pool.query(
          'INSERT INTO attendance (employee_id, employee_name, check_in_time, check_out_time, check_in, check_out, check_in_method) VALUES ($1, $2, $3, $4, $5, $6, $7)',
          [approval.employee_id, approval.employee_name, approval.from_date, approval.to_date, cinStr, coutStr, 'Quản trị viên bổ sung']
        );
        console.log('✅ Đã chèn bản ghi chấm công mới thành công.');
      } catch (insertErr) {
        console.error('❌ Lỗi khi chèn bản ghi chấm công bổ sung:', insertErr.message);
      }
    }

    // 3. Thông báo Real-time sau khi đã chuẩn bị xong dữ liệu
    io.emit('approval_updated', approval);
    io.emit('attendance_updated'); // Thông báo cho Web Admin cập nhật danh sách chấm công


    // Gửi Push Notification
    const statusText = status === 'approved' ? 'được PHÊ DUYỆT' : 'bị TỪ CHỐI';
    await sendPushNotification(
      approval.employee_id,
      'Cập nhật yêu cầu',
      `Yêu cầu "${approval.type}" của bạn đã ${statusText}.`,
      { type: 'approval', id: approval.id.toString() }
    );

    // Lưu vào user_notifications
    await pool.query(
      "INSERT INTO user_notifications (employee_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5)",
      [
        approval.employee_id, 
        'Cập nhật yêu cầu', 
        `Yêu cầu "${approval.type}" của bạn đã ${statusText}.`, 
        'approval', 
        JSON.stringify({ id: approval.id, status })
      ]
    );

    res.json(approval);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/approvals/check-forgot-limit', async (req, res) => {
  const { employee_id, month } = req.body; // month: YYYY-MM
  try {
    const r = await pool.query(
      "SELECT COUNT(*) FROM approvals WHERE employee_id = $1 AND type = 'Quên chấm công' AND status != 'rejected' AND to_char(created_at, 'YYYY-MM') = $2",
      [employee_id, month]
    );
    res.json({ count: parseInt(r.rows[0].count) });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/overtimes', async (req, res) => {
  console.log('📥 Nhận yêu cầu OT mới:', req.body);
  try {
    const { employee_id, employee_name, date, hours, reason } = req.body;
    const result = await pool.query(
      'INSERT INTO approvals (employee_id, employee_name, type, reason, from_date, to_date, total_hours, status) VALUES ($1, $2, \'Làm thêm giờ\', $3, $4, $4, $5, \'pending\') RETURNING *',
      [employee_id, employee_name, reason, date, hours]
    );
    console.log('✅ Đã lưu đơn OT vào DB:', result.rows[0].id);
    io.emit('new_approval', result.rows[0]);
    res.json(result.rows[0]);
  } catch (err) { 
    console.error('❌ Lỗi lưu đơn OT:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

// --- 7. API THỐNG KÊ (STATISTICS) ---
app.get('/api/statistics/:employeeId', async (req, res) => {
  const { employeeId } = req.params;
  const { period, start_date, end_date } = req.query; // 'week', 'month', 'year' hoặc khoảng ngày cụ thể
  
  try {
    // 1. Lấy dữ liệu điểm danh
    let dateFilter = "";
    let params = [employeeId];

    if (start_date && end_date) {
      dateFilter = "AND check_in_time::date >= $2 AND check_in_time::date <= $3";
      params.push(start_date, end_date);
    } else {
      if (period === 'month') dateFilter = "AND check_in_time >= date_trunc('month', NOW())";
      else if (period === 'year') dateFilter = "AND check_in_time >= date_trunc('year', NOW())";
      else dateFilter = "AND check_in_time >= NOW() - INTERVAL '7 days'";
    }

    const attendance = await pool.query(
      `SELECT * FROM attendance WHERE employee_id = $1 ${dateFilter} ORDER BY check_in_time DESC`,
      params
    );

    // 2. Lấy cấu hình và OT để tính toán
    const configRes = await pool.query('SELECT * FROM company_config LIMIT 1');
    const config = configRes.rows[0];

    const otRes = await pool.query(`
      SELECT to_char(from_date, 'YYYY-MM-DD') as date, SUM(total_hours) as hours
      FROM approvals 
      WHERE employee_id = $1 AND status = 'approved' AND type = 'Làm thêm giờ'
      GROUP BY to_char(from_date, 'YYYY-MM-DD')
    `, [employeeId]);
    const otMap = {};
    otRes.rows.forEach(row => { otMap[row.date] = parseFloat(row.hours); });

    let totalNormalHours = 0;
    let totalOTHours = 0;
    let lateDays = 0;
    
    const weeklyData = Array(7).fill(0).map(() => ({ normal: 0, ot: 0, deficiency: 0 }));
    
    attendance.rows.forEach(row => {
      const dateStr = new Date(row.check_in_time).toISOString().split('T')[0];
      const approvedOT = otMap[dateStr] || 0;
      const hours = calculateWorkingHours(row.check_in_time, row.check_out_time, config, approvedOT);
      
      totalNormalHours += hours.normal;
      totalOTHours += hours.ot;

      const dayIdx = (new Date(row.check_in_time).getDay() + 6) % 7;
      weeklyData[dayIdx].normal = hours.normal;
      weeklyData[dayIdx].ot = hours.ot;
      
      // Gán OT vào từng dòng để trả về cho App hiển thị ở mục Lịch sử
      row.ot_hours = approvedOT;
      
      // Kiểm tra đi muộn (So với work_start_time trong config)
      const checkInHour = new Date(row.check_in_time).getHours();
      const checkInMin = new Date(row.check_in_time).getMinutes();
      const [limitHour, limitMin] = (config.work_start_time || '08:30').split(':').map(Number);
      
      if (checkInHour > limitHour || (checkInHour === limitHour && checkInMin > limitMin)) {
        lateDays++;
      }
    });

    // 3. Lấy số ngày nghỉ từ approvals (Xử lý dữ liệu lỗi/ngược ngày)
    const leavesQuery = await pool.query(
      `SELECT 
        id, type, total_hours, from_date, to_date, is_half_day,
        CASE 
          WHEN total_hours IS NOT NULL AND total_hours > 0 THEN total_hours
          WHEN is_half_day = true THEN 4
          ELSE GREATEST(1, ABS(DATE_PART('day', to_date::timestamp - from_date::timestamp)) + 1) * 8
        END as calculated_hours
       FROM approvals 
       WHERE employee_id::text = $1::text 
       AND status IN ('approved', 'pending') 
       AND (LOWER(type) LIKE '%nghỉ%' OR LOWER(type) LIKE '%phép%')
       AND LOWER(type) NOT LIKE '%thêm%'`,
      [employeeId]
    );

    let usedLeaveHours = 0;
    console.log(`--- [Statistics] Leave Debug for ${employeeId} ---`);
    leavesQuery.rows.forEach(row => {
      usedLeaveHours += parseFloat(row.calculated_hours);
      console.log(`ID: ${row.id}, Type: ${row.type}, Calc: ${row.calculated_hours}h (DB: ${row.total_hours}h)`);
    });
    console.log(`Total Used: ${usedLeaveHours}h`);
    
    const remainingLeaveDays = Math.max(0, 12 - (usedLeaveHours / 8));
    console.log(`Final Remaining: ${remainingLeaveDays} days`);

    res.json({
      totalHours: (totalNormalHours + totalOTHours).toFixed(1),
      totalNormalHours: totalNormalHours.toFixed(1),
      totalOTHours: totalOTHours.toFixed(1),
      lateDays,
      remainingLeave: remainingLeaveDays.toFixed(1),
      weeklyData,
      history: attendance.rows
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// --- 6. API CHAT & AI BOT ---
const HybridChatbot = require('./hybrid_chatbot');

// Lịch sử AI riêng
app.get('/api/chat/ai-history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const r = await pool.query(`
      SELECT m.*, e.name as sender_name 
      FROM chat_messages m
      LEFT JOIN employees e ON m.sender_id = e.id
      WHERE m.sender_id = $1 AND m.chat_type = 'ai'
      ORDER BY created_at ASC
    `, [userId]);
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/chat/upload', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Không có tệp nào được tải lên.' });
  res.json({
    file_url: `/uploads/chat/${req.file.filename}`,
    file_name: req.file.originalname,
    file_type: req.file.mimetype
  });
});

// Lịch sử Admin riêng (cho Flutter app)
app.get('/api/chat/admin-history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const r = await pool.query(`
      SELECT m.*, e.name as sender_name 
      FROM chat_messages m
      LEFT JOIN employees e ON m.sender_id = e.id
      WHERE m.chat_type = 'admin' 
        AND (m.sender_id = $1 OR m.receiver_id = $1)
      ORDER BY created_at ASC
    `, [userId]);
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Lịch sử chat theo userId (cho Web Admin dùng)
app.get('/api/chat/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const r = await pool.query(`
      SELECT m.*, e.name as sender_name 
      FROM chat_messages m
      LEFT JOIN employees e ON m.sender_id = e.id
      WHERE m.chat_type = 'admin'
        AND (m.sender_id = $1 OR m.receiver_id = $1)
      ORDER BY created_at ASC
    `, [userId]);
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/chat/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    await pool.query("DELETE FROM chat_messages WHERE chat_type = 'admin' AND (sender_id = $1 OR receiver_id = $1)", [userId]);
    res.json({ message: 'Đã xóa toàn bộ lịch sử chat.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/chat/admin/conversations', async (req, res) => {
  try {
    const r = await pool.query(`
      SELECT DISTINCT ON (u.id) 
        u.id, u.name, u.email, u.position, u.department_name, u.avatar_url,
        m.message as last_message, m.created_at as last_message_time
      FROM employees u
      JOIN chat_messages m ON m.sender_id = u.id
      WHERE u.role != 'admin' AND m.chat_type = 'admin'
      ORDER BY u.id, m.created_at DESC
    `);
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/chat/ai', async (req, res) => {
  try {
    const { userId, message } = req.body;
    
    // Lưu câu hỏi của user (chat_type='ai')
    await pool.query(
      "INSERT INTO chat_messages (sender_id, message, is_ai, chat_type) VALUES ($1, $2, false, 'ai')",
      [userId, message]
    );

    const bot = new HybridChatbot(pool);
    const result = await bot.processMessage(userId, message);
    const reply = result.text;

    // Lưu câu trả lời AI (chat_type='ai', is_ai=true)
    await pool.query(
      "INSERT INTO chat_messages (sender_id, message, is_ai, chat_type) VALUES ($1, $2, true, 'ai')",
      [userId, reply]
    );

    res.json({ 
      reply, 
      suggestAdmin: result.action === 'open_admin_chat',
      suggestions: result.suggestions || [],
      source: result.source || 'rule'
    });
  } catch (err) { 
    console.error('❌ Lỗi AI Chat:', err.message);
    res.status(500).json({ error: err.message, reply: "Xin lỗi, tôi đang gặp sự cố. Vui lòng thử lại hoặc chat với Admin.", suggestAdmin: true, suggestions: ['Thử lại'], source: 'system' }); 
  }
});

// Lấy danh sách hội thoại của user
app.get('/api/conversations', async (req, res) => {
  try {
    const { userId } = req.query;

    const result = await pool.query(`
      SELECT 
        c.id, c.type, c.name,
        CASE WHEN c.type='direct' THEN 
          (SELECT name FROM employees WHERE id != $1
           AND id IN (SELECT user_id FROM conversation_members WHERE conversation_id=c.id) LIMIT 1)
        ELSE c.name END AS display_name,
        (SELECT message FROM chat_messages WHERE conversation_id=c.id ORDER BY created_at DESC LIMIT 1) AS last_message,
        (SELECT created_at FROM chat_messages WHERE conversation_id=c.id ORDER BY created_at DESC LIMIT 1) AS last_message_time,
        (SELECT name FROM employees WHERE id=(
          SELECT sender_id FROM chat_messages WHERE conversation_id=c.id ORDER BY created_at DESC LIMIT 1
        )) AS sender_name,
        (SELECT COUNT(*) FROM chat_messages m 
         WHERE m.conversation_id=c.id 
         AND m.created_at > COALESCE(
           (SELECT last_read_at FROM conversation_members WHERE conversation_id=c.id AND user_id=$1), 
           '1970-01-01'
         )) AS unread_count
      FROM conversations c
      JOIN conversation_members cm ON cm.conversation_id=c.id
      WHERE cm.user_id=$1
      ORDER BY last_message_time DESC NULLS LAST
    `, [userId]);

    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/conversations/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const r = await pool.query(`
      SELECT m.*, e.name as sender_name 
      FROM chat_messages m
      LEFT JOIN employees e ON m.sender_id = e.id
      WHERE m.conversation_id = $1
      ORDER BY created_at ASC
    `, [id]);
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// Tạo nhóm mới
app.post('/api/conversations/group', async (req, res) => {
  const { name, createdBy, memberIds } = req.body;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const conv = await client.query(
      `INSERT INTO conversations (type, name, created_by) VALUES ('group', $1, $2) RETURNING id`,
      [name, createdBy]
    );
    const convId = conv.rows[0].id;
    const allMembers = [...new Set([...memberIds, parseInt(createdBy)])];
    for (const uid of allMembers) {
      await client.query(
        `INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)`,
        [convId, uid]
      );
    }
    await client.query('COMMIT');
    res.json({ id: convId });
  } catch (e) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: e.message });
  } finally {
    client.release();
  }
});

// Lấy đồng nghiệp (trừ admin)
app.get('/api/users/colleagues', async (req, res) => {
  try {
    const { userId } = req.query;
    const r = await pool.query("SELECT id, name as full_name, department_name as department FROM employees WHERE id != $1 AND role != 'admin'", [userId]);
    res.json(r.rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Lấy những người đã từng chat 1-1 (để gợi ý tạo nhóm mới)
app.get('/api/users/chatted-colleagues', async (req, res) => {
  try {
    const { userId } = req.query;
    const r = await pool.query(`
      SELECT DISTINCT e.id, e.name as full_name, e.department_name as department 
      FROM employees e
      JOIN conversation_members cm1 ON e.id = cm1.user_id
      JOIN conversation_members cm2 ON cm1.conversation_id = cm2.conversation_id
      JOIN conversations c ON c.id = cm1.conversation_id
      WHERE cm2.user_id = $1 AND e.id != $1 AND c.type = 'direct'
    `, [userId]);
    res.json(r.rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// --- KHỞI CHẠY SERVER ---
const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 WorkMate Server is clean and running on port ${PORT} (0.0.0.0)`);
});
