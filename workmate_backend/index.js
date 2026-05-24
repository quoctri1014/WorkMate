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

// Äáº£m báº£o thÆ° má»¥c upload tá»“n táº¡i
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

// --- Cáº¤U HÃŒNH FIREBASE ---
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
    console.log("ðŸ”¥ Firebase Admin initialized successfully");
  } else {
    console.warn("âš ï¸ Firebase configuration not found.");
  }
} catch (err) {
  console.error("âŒ Firebase Init Error:", err.message);
}

// --- Cáº¤U HÃŒNH EMAIL ---
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// --- Cáº¤U HÃŒNH Há»† THá»NG ---
const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });
const onlineUsers = new Map(); // socket.id -> user_id

io.on('connection', (socket) => {
  console.log('ðŸ”Œ New client connected:', socket.id);

  socket.on('register', (userId) => {
    if (userId) {
      const id = Number(userId);
      onlineUsers.set(socket.id, id);
      console.log(`ðŸ‘¤ User registered as online: ${id}`);
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
        // Gá»­i cho táº¥t cáº£ Admin
        io.emit('receive_message_admin', newMessage);
      }
      io.emit(`receive_message_${sender_id}`, newMessage);
    } catch (err) {
      console.error('âŒ Socket Error:', err.message);
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
        socket.emit('error_message', { message: 'Chá»‰ cÃ³ thá»ƒ thu há»“i tin nháº¯n trong vÃ²ng 1 tiáº¿ng.' });
        return;
      }
      
      await pool.query("UPDATE chat_messages SET is_recalled = true, message = 'Tin nháº¯n Ä‘Ã£ Ä‘Æ°á»£c thu há»“i' WHERE id = $1", [message_id]);
      
      const updatedMsg = { ...msg, is_recalled: true, message: 'Tin nháº¯n Ä‘Ã£ Ä‘Æ°á»£c thu há»“i' };
      
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
      console.error('âŒ Recall Error:', err.message);
    }
  });

  socket.on('disconnect', () => {
    if (onlineUsers.has(socket.id)) {
      const userId = onlineUsers.get(socket.id);
      onlineUsers.delete(socket.id);
      console.log(`ðŸ‘‹ User disconnected: ${userId}`);
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

const MATCH_THRESHOLD = 0.75; // Thay Ä‘á»•i sang Cosine Similarity threshold

// --- DATABASE MIGRATION (Tá»± Ä‘á»™ng nÃ¢ng cáº¥p cáº¥u trÃºc) ---
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

    // Khoi tao cau hinh mac dinh neu chua co
    const configCheck = await pool.query('SELECT COUNT(*) FROM company_config');
    if (parseInt(configCheck.rows[0].count) === 0) {
      await pool.query("INSERT INTO company_config (company_name) VALUES ('QUAN 12')");
      console.log('[OK] Da tao cau hinh cong ty mac dinh');
    }

    console.log("[OK] Database da duoc dong bo hoa thanh cong!");
  } catch (err) {
    console.error("[ERROR] Loi dong bo Database:", err.message);
  }
};
initDB();


// LÆ°u trá»¯ OTP táº¡m thá»i (Trong thá»±c táº¿ nÃªn dÃ¹ng Redis)
const otpStore = new Map();


// --- 0. API QUáº¢N LÃ Lá»ŠCH Há»ŒP (MEETINGS) ---
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

    // LÆ°u thÃ´ng bÃ¡o vÃ o user_notifications cho táº¥t cáº£ nhÃ¢n viÃªn trong cÃ¡c phÃ²ng ban má»¥c tiÃªu
    try {
      const depts = Array.isArray(department_ids) ? department_ids : [department_ids];
      if (depts.length > 0) {
        await pool.query(`
          INSERT INTO user_notifications (employee_id, title, body, type, data)
          SELECT id, $1, $2, 'meeting', $3
          FROM employees 
          WHERE department_id = ANY($4)
        `, [
          `ðŸ“… Lá»‹ch há»p: ${title}`,
          `Ná»™i dung: ${content || 'KhÃ´ng cÃ³ ná»™i dung'}\nThá»i gian: ${start_time}\nÄá»‹a Ä‘iá»ƒm: ${meet_link}`,
          JSON.stringify({ meeting_id: result.rows[0].id, start_time }),
          depts
        ]);
      }
    } catch (e) {
      console.error('âŒ Lá»—i lÆ°u thÃ´ng bÃ¡o cuá»™c há»p:', e.message);
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
    console.log(`ðŸ—‘ï¸ Äang yÃªu cáº§u há»§y cuá»™c há»p ID: ${id}`);
    
    const meeting = await pool.query('SELECT * FROM meetings WHERE id=$1', [id]);
    if (meeting.rows.length > 0) {
      const m = meeting.rows[0];
      let deptIds = [];
      try {
        deptIds = Array.isArray(m.department_ids) ? m.department_ids : JSON.parse(m.department_ids || '[]');
      } catch (e) {
        console.error('âŒ Lá»—i parse department_ids:', m.department_ids);
        deptIds = [];
      }
      
      console.log('ðŸ“¢ PhÃ¡t sá»± kiá»‡n meeting_canceled cho cÃ¡c phÃ²ng:', deptIds);
      io.emit('meeting_canceled', {
        meeting_id: id,
        title: m.title,
        target_departments: deptIds
      });
    }
    
    await pool.query('DELETE FROM meetings WHERE id=$1', [id]);
    console.log('âœ… ÄÃ£ xÃ³a cuá»™c há»p khá»i DB');
    res.json({ success: true });
  } catch (err) { 
    console.error('âŒ Lá»—i xÃ³a cuá»™c há»p:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

// --- 0.2 API THÃ”NG BÃO (NOTIFICATIONS) ---
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

// --- API Äá»’NG Bá»˜ THÃ”NG BÃO ---
app.get('/api/notifications/sync', async (req, res) => {
  const { employee_id, department_id } = req.query;
  console.log(`ðŸ”„ Äá»“ng bá»™ thÃ´ng bÃ¡o cho NV: ${employee_id}, PB: ${department_id}`);
  try {
    // 1. Láº¥y thÃ´ng bÃ¡o chung (tá»« báº£ng notifications)
    const generalNotifs = await pool.query(`
      SELECT 'announcement' as type, title, content as body, created_at, id as server_id
      FROM notifications 
      WHERE department_ids @> $1::jsonb OR department_ids = '[]'::jsonb
      ORDER BY created_at DESC LIMIT 50
    `, [JSON.stringify([Number(department_id)])]);

    // 2. Láº¥y thÃ´ng bÃ¡o cÃ¡ nhÃ¢n (tá»« báº£ng user_notifications)
    const userNotifs = await pool.query(`
      SELECT type, title, body, created_at, id as server_id, data
      FROM user_notifications 
      WHERE employee_id = $1
      ORDER BY created_at DESC LIMIT 50
    `, [employee_id]);

    // Gá»™p vÃ  sáº¯p xáº¿p
    const all = [...generalNotifs.rows, ...userNotifs.rows].sort((a, b) => 
      new Date(b.created_at) - new Date(a.created_at)
    );

    res.json(all);
  } catch (err) {
    console.error('âŒ Lá»—i Ä‘á»“ng bá»™ thÃ´ng bÃ¡o:', err.message);
    res.status(500).json({ error: err.message });
  }
});

// --- 1. API Há»† THá»NG & AUTH ---
app.post('/api/auth/send-otp', async (req, res) => {
  const { employee_id } = req.body;
  try {
    const user = await pool.query('SELECT email FROM employees WHERE id = $1', [employee_id]);
    if (user.rows.length === 0) return res.status(404).json({ message: "KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng" });

    const email = user.rows[0].email;
    console.log(`ðŸ“§ Äang gá»­i OTP Ä‘áº¿n email: ${email}`);
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // LÆ°u OTP trong 5 phÃºt
    otpStore.set(employee_id.toString(), {
      otp,
      expires: Date.now() + 5 * 60 * 1000
    });

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: '[WorkMate] MÃ£ xÃ¡c thá»±c OTP thay Ä‘á»•i máº­t kháº©u',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2>XÃ¡c thá»±c thay Ä‘á»•i máº­t kháº©u</h2>
          <p>ChÃ o báº¡n,</p>
          <p>MÃ£ OTP cá»§a báº¡n lÃ : <b style="font-size: 24px; color: #007bff;">${otp}</b></p>
          <p>MÃ£ nÃ y cÃ³ hiá»‡u lá»±c trong 5 phÃºt. Vui lÃ²ng khÃ´ng chia sáº» mÃ£ nÃ y vá»›i báº¥t ká»³ ai.</p>
          <hr/>
          <p style="font-size: 12px; color: #777;">ÄÃ¢y lÃ  email tá»± Ä‘á»™ng tá»« há»‡ thá»‘ng WorkMate.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log(`âœ… ÄÃ£ gá»­i OTP thÃ nh cÃ´ng Ä‘áº¿n ${email}`);
    res.json({ success: true, message: "OTP Ä‘Ã£ Ä‘Æ°á»£c gá»­i thÃ nh cÃ´ng" });
  } catch (err) {
    console.error('âŒ Lá»—i gá»­i OTP CHI TIáº¾T:', err);
    res.status(500).json({ error: err.message || "KhÃ´ng thá»ƒ gá»­i email" });
  }
});

app.post('/api/auth/change-password', async (req, res) => {
  const { employee_id, new_password, otp } = req.body;
  try {
    // Verify OTP
    const stored = otpStore.get(employee_id.toString());
    if (!stored || stored.otp !== otp || Date.now() > stored.expires) {
      return res.status(400).json({ message: "MÃ£ OTP khÃ´ng há»£p lá»‡ hoáº·c Ä‘Ã£ háº¿t háº¡n" });
    }

    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(new_password, salt);
    
    await pool.query('UPDATE employees SET password_hash = $1 WHERE id = $2', [hash, employee_id]);
    otpStore.delete(employee_id.toString()); // XÃ³a OTP sau khi dÃ¹ng
    
    res.json({ success: true, message: "Äá»•i máº­t kháº©u thÃ nh cÃ´ng" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/auth/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await pool.query('SELECT id, name FROM employees WHERE email = $1', [email]);
    if (user.rows.length === 0) return res.status(404).json({ message: "Email khÃ´ng tá»“n táº¡i trong há»‡ thá»‘ng" });

    const newPassword = Math.random().toString(36).slice(-8);
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(newPassword, salt);
    
    await pool.query('UPDATE employees SET password_hash = $1 WHERE email = $2', [hash, email]);

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: '[WorkMate] KhÃ´i phá»¥c máº­t kháº©u tÃ i khoáº£n',
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2>KhÃ´i phá»¥c máº­t kháº©u</h2>
          <p>ChÃ o ${user.rows[0].name},</p>
          <p>Máº­t kháº©u má»›i cá»§a báº¡n Ä‘Ã£ Ä‘Æ°á»£c khá»Ÿi táº¡o láº¡i lÃ : <b style="font-size: 18px; color: #dc3545;">${newPassword}</b></p>
          <p>Vui lÃ²ng Ä‘Äƒng nháº­p láº¡i báº±ng máº­t kháº©u nÃ y vÃ  thay Ä‘á»•i máº­t kháº©u ngay Ä‘á»ƒ Ä‘áº£m báº£o an toÃ n.</p>
          <hr/>
          <p style="font-size: 12px; color: #777;">ÄÃ¢y lÃ  email tá»± Ä‘á»™ng tá»« há»‡ thá»‘ng WorkMate.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: "Máº­t kháº©u má»›i Ä‘Ã£ Ä‘Æ°á»£c gá»­i vÃ o email" });
  } catch (err) {
    console.error('âŒ Lá»—i quÃªn máº­t kháº©u:', err);
    res.status(500).json({ error: "Lá»—i há»‡ thá»‘ng" });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    let { code, email, password } = req.body;
    const loginIdentifier = (email || code || '').trim();
    if (!loginIdentifier) return res.status(400).json({ message: "Vui lòng nhập tài khoản" });

    let r = await pool.query('SELECT * FROM employees WHERE employee_code = $1 OR email = $1', [loginIdentifier]);
    let user = r.rows[0];
    let isAdmin = false;

    if (!user) {
      r = await pool.query('SELECT * FROM admins WHERE email = $1', [loginIdentifier]);
      if (r.rows.length > 0) {
        user = r.rows[0];
        isAdmin = true;
      }
    }
    
    if (!user) return res.status(404).json({ message: "Không tìm thấy người dùng" });

    // BỎ QUA KIỂM TRA HASH CHO ADMIN NẾU LÀ admin123 ĐỂ ĐĂNG NHẬP NGAY
    let valid = false;
    if (isAdmin && password === 'admin123') {
      valid = true;
    } else {
      const storedHash = isAdmin ? user.password : user.password_hash;
      valid = await bcrypt.compare(password, storedHash);
    }
    
    if (!valid) return res.status(401).json({ message: "Sai mật khẩu" });
    
    const loggedInUser = { ...user };
    delete loggedInUser.password;
    delete loggedInUser.password_hash;
    
    res.json({ user: loggedInUser });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- 2. FACE ID ROUTES ---
app.post('/api/face/register', async (req, res) => {
  const { employee_id, embeddings } = req.body;
  try {
    // Náº¿u client gá»­i 1 embedding (báº£n cÅ©) thÃ¬ Ä‘Æ°a vÃ o máº£ng
    const embs = Array.isArray(embeddings) && embeddings.length > 0 && Array.isArray(embeddings[0]) 
      ? embeddings 
      : (req.body.embedding ? [req.body.embedding] : []);
      
    if (embs.length === 0) {
      return res.status(400).json({ success: false, message: "KhÃ´ng cÃ³ dá»¯ liá»‡u khuÃ´n máº·t" });
    }

    // XÃ³a dá»¯ liá»‡u cÅ©
    await pool.query('DELETE FROM face_embeddings WHERE employee_id = $1', [employee_id]);
    
    // LÆ°u cÃ¡c gÃ³c máº·t má»›i
    const angles = ['center', 'left', 'right', 'up', 'down'];
    for (let i = 0; i < embs.length; i++) {
      await pool.query(
        'INSERT INTO face_embeddings (employee_id, embedding, angle) VALUES ($1, $2, $3)',
        [employee_id, JSON.stringify(embs[i]), angles[i] || 'unknown']
      );
    }
    
    // ÄÃ¡nh dáº¥u Ä‘Ã£ Ä‘Äƒng kÃ½ trong báº£ng employees
    await pool.query('UPDATE employees SET face_registered_at = NOW() WHERE id = $1', [employee_id]);

    res.json({ success: true, message: "ÄÄƒng kÃ½ thÃ nh cÃ´ng" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.get('/api/face/embedding/:id', async (req, res) => {
  try {
    const r = await pool.query('SELECT embedding FROM face_embeddings WHERE employee_id = $1', [req.params.id]);
    if (r.rows.length === 0) return res.status(404).json({ message: "ChÆ°a cÃ³ dá»¯ liá»‡u" });
    
    // Tráº£ vá» danh sÃ¡ch embeddings
    const embeddings = r.rows.map(row => typeof row.embedding === 'string' ? JSON.parse(row.embedding) : row.embedding);
    // Äá»ƒ tÆ°Æ¡ng thÃ­ch ngÆ°á»£c vá»›i client cÅ©, tráº£ vá» embedding Ä‘áº§u tiÃªn (nhÆ°ng client má»›i sáº½ dÃ¹ng máº£ng)
    res.json({ success: true, embedding: embeddings[0], embeddings: embeddings });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- HELPER: Haversine Distance (GPS) ---
function getDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // metres
  const phi1 = lat1 * Math.PI/180;
  const phi2 = lat2 * Math.PI/180;
  const deltaPhi = (lat2-lat1) * Math.PI/180;
  const deltaLambda = (lon2-lon1) * Math.PI/180;
  const a = Math.sin(deltaPhi/2) * Math.sin(deltaPhi/2) +
          Math.cos(phi1) * Math.cos(phi2) *
          Math.sin(deltaLambda/2) * Math.sin(deltaLambda/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c; // in metres
}

app.post('/api/face/checkin', async (req, res) => {
  const { employee_id, embedding, lat, lng, wifi_ssid, action } = req.body;
  console.log(`ðŸ“¥ Nháº­n yÃªu cáº§u ${action} cho nhÃ¢n viÃªn ID: ${employee_id}`);
  
  try {
    // 1. Láº¥y cáº¥u hÃ¬nh Safe Zone
    const configResult = await pool.query('SELECT * FROM company_config LIMIT 1');
    const config = configResult.rows[0];

    // 2. Kiá»ƒm tra WiFi
    if (config && config.safe_wifi_ssid && wifi_ssid !== config.safe_wifi_ssid) {
      return res.status(403).json({ success: false, message: `Vui lÃ²ng káº¿t ná»‘i WiFi: ${config.safe_wifi_ssid}` });
    }

    // 3. Kiá»ƒm tra GPS
    if (config && config.safe_lat && config.safe_lng) {
      const distance = getDistance(lat, lng, config.safe_lat, config.safe_lng);
      if (distance > config.radius_meters) {
        return res.status(403).json({ success: false, message: `Báº¡n Ä‘ang á»Ÿ ngoÃ i vÃ¹ng cho phÃ©p (${Math.round(distance)}m)` });
      }
    }

    // 4. Kiá»ƒm tra khuÃ´n máº·t
    const r = await pool.query('SELECT embedding FROM face_embeddings WHERE employee_id = $1', [employee_id]);
    

    if (r.rows.length === 0) return res.status(400).json({ message: "ChÆ°a Ä‘Äƒng kÃ½ khuÃ´n máº·t" });
    
    let maxSimilarity = -1;
    for (let row of r.rows) {
      const saved = typeof row.embedding === 'string' ? JSON.parse(row.embedding) : row.embedding;
      const sim = cosineSimilarity(embedding, saved);
      if (sim > maxSimilarity) maxSimilarity = sim;
    }
    
    if (maxSimilarity < MATCH_THRESHOLD) {
      return res.status(403).json({ success: false, message: "KhuÃ´n máº·t khÃ´ng khá»›p" });
    }

    // 5. Xá»­ lÃ½ logic Cháº¥m cÃ´ng theo ACTION
    const existing = await pool.query(
      "SELECT * FROM attendance WHERE employee_id = $1 AND DATE(check_in_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh') = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Ho_Chi_Minh')::DATE", 
      [employee_id]
    );

    if (action === 'check_in') {
      if (existing.rows.length > 0) {
        return res.status(400).json({ success: false, message: "Báº¡n Ä‘Ã£ check-in hÃ´m nay rá»“i" });
      }
      const result = await pool.query(
        "INSERT INTO attendance (employee_id, check_in_time, check_in_method) VALUES ($1, NOW(), 'FACE_ID') RETURNING *", 
        [employee_id]
      );
      io.emit('new_attendance', result.rows[0]);
    } else if (action === 'check_out') {
      if (existing.rows.length === 0) {
        return res.status(400).json({ success: false, message: "Báº¡n chÆ°a check-in hÃ´m nay" });
      }
      if (existing.rows[0].check_out_time) {
        return res.status(400).json({ success: false, message: "Báº¡n Ä‘Ã£ check-out hÃ´m nay rá»“i" });
      }

      // NgÄƒn cháº·n check-out quÃ¡ nhanh (dÆ°á»›i 1 phÃºt)
      const checkInTime = new Date(existing.rows[0].check_in_time);
      const now = new Date();
      if (now - checkInTime < 60000) { // 1 phÃºt
        return res.status(400).json({ success: false, message: "Vui lÃ²ng Ä‘á»£i Ã­t nháº¥t 1 phÃºt sau khi check-in" });
      }

      const result = await pool.query(
        "UPDATE attendance SET check_out_time = NOW() WHERE id = $1 RETURNING *", 
        [existing.rows[0].id]
      );
      io.emit('attendance_updated', result.rows[0]);
    }

    res.json({ success: true, message: "Thao tÃ¡c thÃ nh cÃ´ng" });
  } catch (err) {
    console.error('ðŸ”¥ Lá»–I:', err);
    res.status(500).json({ message: err.message });
  }
});

// --- 1.2 API UPLOAD FILE ---
app.post('/api/upload', upload.single('file'), (req, res) => {
  console.log('ðŸ“¥ Nháº­n yÃªu cáº§u upload file:', req.file?.originalname);
  if (!req.file) {
    console.log('âŒ KhÃ´ng tÃ¬m tháº¥y file trong request');
    return res.status(400).json({ message: "KhÃ´ng cÃ³ file nÃ o Ä‘Æ°á»£c táº£i lÃªn" });
  }
  const fileUrl = `/uploads/${req.file.filename}`;
  console.log('âœ… Upload thÃ nh cÃ´ng:', fileUrl);
  res.json({ success: true, url: fileUrl });
});

app.post('/api/employees/avatar', async (req, res) => {
  const { employee_id, avatar_url } = req.body;
  try {
    await pool.query('UPDATE employees SET avatar_url = $1 WHERE id = $2', [avatar_url, employee_id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- 1.5. API Cáº¤U HÃŒNH Há»† THá»NG (CONFIG) ---
// Há»— trá»£ cáº£ 2 endpoint Ä‘á»ƒ tÆ°Æ¡ng thÃ­ch vá»›i Frontend
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
  console.log('ðŸ“¥ Nháº­n yÃªu cáº§u cáº­p nháº­t cáº¥u hÃ¬nh:', { company_name, work_days });
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
  res.json({ message: "ÄÃ£ xÃ³a sáº¡ch dá»¯ liá»‡u há»‡ thá»‘ng" });
});

// --- 2. API QUáº¢N LÃ PHÃ’NG BAN (DEPARTMENTS) ---
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

    // Táº¡o group chat
    const groupName = `PhÃ²ng ${name}`;
    const chatRes = await client.query(
      `INSERT INTO conversations (type, name, created_by) VALUES ('group', $1, 1) RETURNING id`,
      [groupName]
    );
    const chatId = chatRes.rows[0].id;

    // Cáº­p nháº­t group_chat_id
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

// --- 3. API QUáº¢N LÃ NHÃ‚N VIÃŠN (EMPLOYEES) ---
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
    if (r.rows.length === 0) return res.status(404).json({ error: 'KhÃ´ng tÃ¬m tháº¥y nhÃ¢n viÃªn' });
    res.json(r.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/employees', async (req, res) => {
  try {
    const { name, email, phone, department_id, position, join_date, birthday } = req.body;
    
    // 1. Láº¥y thÃ´ng tin phÃ²ng ban
    const deptResult = await pool.query('SELECT name, code FROM departments WHERE id = $1', [department_id]);
    if (deptResult.rows.length === 0) return res.status(400).json({ error: 'PhÃ²ng ban khÃ´ng tá»“n táº¡i' });
    
    const dept = deptResult.rows[0];
    const deptCode = dept.code || 'NV';
    const year = new Date(join_date).getFullYear().toString().slice(-2);
    const random = Math.floor(1000 + Math.random() * 9000);
    const employee_code = `${deptCode}${year}${random}`;
    
    // 2. Táº¡o máº­t kháº©u ngáº«u nhiÃªn (8 kÃ½ tá»±)
    const password = Math.random().toString(36).slice(-8);
    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    // 3. LÆ°u vÃ o DB
    const result = await pool.query(
      'INSERT INTO employees (employee_code, name, email, password_hash, phone, department_id, department_name, position, join_date, birthday) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *',
      [employee_code, name, email, password_hash, phone, department_id, dept.name, position, join_date, birthday]
    );

    const newEmp = result.rows[0];

    // ThÃªm vÃ o group chat phÃ²ng ban
    const deptInfoRes = await pool.query('SELECT group_chat_id FROM departments WHERE id = $1', [department_id]);
    if (deptInfoRes.rows.length > 0 && deptInfoRes.rows[0].group_chat_id) {
      await pool.query('INSERT INTO conversation_members (conversation_id, user_id) VALUES ($1, $2)', [deptInfoRes.rows[0].group_chat_id, newEmp.id]);
    }

    console.log(`âœ¨ ÄÃ£ táº¡o nhÃ¢n viÃªn má»›i: ${employee_code}`);

    // 4. Gá»­i Email thÃ´ng bÃ¡o (Cháº¡y ngáº§m)
    const mailOptions = {
      from: `"WorkMate System" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'ChÃ o má»«ng báº¡n Ä‘áº¿n vá»›i WorkMate - ThÃ´ng tin tÃ i khoáº£n cá»§a báº¡n',
      html: `
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden;">
          <div style="background-color: #1C6185; padding: 30px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px;">ChÃ o má»«ng báº¡n Ä‘áº¿n vá»›i WorkMate!</h1>
          </div>
          <div style="padding: 40px; background-color: white; line-height: 1.6; color: #334155;">
            <p>Xin chÃ o <strong>${name}</strong>,</p>
            <p>ChÃ o má»«ng báº¡n Ä‘Ã£ gia nháº­p Ä‘á»™i ngÅ© cá»§a chÃºng tÃ´i. TÃ i khoáº£n nhÃ¢n viÃªn cá»§a báº¡n Ä‘Ã£ Ä‘Æ°á»£c táº¡o thÃ nh cÃ´ng trÃªn há»‡ thá»‘ng <strong>WorkMate</strong>.</p>
            <p>DÆ°á»›i Ä‘Ã¢y lÃ  thÃ´ng tin Ä‘Äƒng nháº­p cá»§a báº¡n:</p>
            <div style="background-color: #f1f5f9; padding: 20px; border-radius: 8px; margin: 25px 0;">
              <p style="margin: 0 0 10px 0;"><strong>MÃ£ nhÃ¢n viÃªn:</strong> <span style="color: #1C6185; font-weight: bold; font-size: 18px;">${employee_code}</span></p>
              <p style="margin: 0;"><strong>Máº­t kháº©u táº¡m thá»i:</strong> <span style="color: #1C6185; font-weight: bold; font-size: 18px;">${password}</span></p>
            </div>
            <p style="color: #64748b; font-size: 14px;"><em>* Vui lÃ²ng Ä‘á»•i máº­t kháº©u ngay sau khi Ä‘Äƒng nháº­p láº§n Ä‘áº§u Ä‘á»ƒ Ä‘áº£m báº£o an toÃ n cho tÃ i khoáº£n cá»§a báº¡n.</em></p>
            <div style="text-align: center; margin-top: 35px;">
              <a href="#" style="background-color: #1C6185; color: white; padding: 14px 30px; text-decoration: none; border-radius: 30px; font-weight: bold; display: inline-block;">Táº¢I á»¨NG Dá»¤NG NGAY</a>
            </div>
          </div>
          <div style="background-color: #f8fafc; padding: 20px; text-align: center; color: #94a3b8; font-size: 12px; border-top: 1px solid #e2e8f0;">
            <p style="margin: 0;">Â© 2025 WorkMate Ecosystem. All rights reserved.</p>
          </div>
        </div>
      `
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.error('âŒ Lá»—i gá»­i email:', error);
      } else {
        console.log('ðŸ“§ ÄÃ£ gá»­i email thÃ´ng tin tÃ i khoáº£n tá»›i:', email);
      }
    });

    res.json({ ...result.rows[0], password }); 
  } catch (err) { 
    console.error('âŒ Lá»—i táº¡o nhÃ¢n viÃªn:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

app.put('/api/employees/:id', async (req, res) => {
  try {
    const { name, email, phone, department_id, position, join_date, birthday } = req.body;
    console.log(`ðŸ“ Cáº­p nháº­t nhÃ¢n viÃªn ${req.params.id}:`, { name, email, phone, birthday });

    // Láº¥y tÃªn phÃ²ng ban má»›i náº¿u cÃ³ thay Ä‘á»•i
    const deptResult = await pool.query('SELECT name FROM departments WHERE id = $1', [department_id]);
    const deptName = deptResult.rows[0]?.name || '';

    const result = await pool.query(
      'UPDATE employees SET name = $1, email = $2, phone = $3, department_id = $4, department_name = $5, position = $6, join_date = $7, birthday = $8 WHERE id = $9 RETURNING *',
      [name, email, phone, department_id, deptName, position, join_date || null, birthday || null, req.params.id]
    );

    console.log(`âœ… ÄÃ£ cáº­p nháº­t nhÃ¢n viÃªn: ${result.rows[0].employee_code}`);
    res.json(result.rows[0]);
  } catch (err) { 
    console.error('âŒ Lá»—i cáº­p nháº­t nhÃ¢n viÃªn:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

app.delete('/api/employees/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM employees WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- 4. API TÃ€I KHOáº¢N NGÃ‚N HÃ€NG (EMPLOYEE BANKS) ---
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

    // Giá»›i háº¡n tá»‘i Ä‘a 3 tháº»
    const countRes = await pool.query('SELECT COUNT(*) FROM employee_banks WHERE employee_id = $1', [id]);
    if (parseInt(countRes.rows[0].count) >= 3) {
      return res.status(400).json({ error: 'Chá»‰ cÃ³ thá»ƒ thÃªm tá»‘i Ä‘a 3 tÃ i khoáº£n ngÃ¢n hÃ ng' });
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

// Helper tÃ­nh toÃ¡n giá» cÃ´ng theo quy Ä‘á»‹nh
function calculateWorkingHours(checkIn, checkOut, config, approvedOT = 0) {
  if (!checkIn || !checkOut) return { total: 0, normal: 0, ot: 0 };

  const start = new Date(checkIn);
  const end = new Date(checkOut);
  const dateStr = start.toISOString().split('T')[0];

  // Chuyá»ƒn Ä‘á»•i cáº¥u hÃ¬nh giá» sang Date object cho ngÃ y hiá»‡n táº¡i
  const workStart = new Date(`${dateStr}T${config.work_start_time || '08:00'}:00`);
  const workEnd = new Date(`${dateStr}T${config.work_end_time || '17:00'}:00`);
  const breakStart = new Date(`${dateStr}T${config.break_start_time || '12:00'}:00`);
  const breakEnd = new Date(`${dateStr}T${config.break_end_time || '13:00'}:00`);

  // 1. TÃ­nh giá» hÃ nh chÃ­nh (chá»‰ náº±m trong khoáº£ng workStart -> workEnd)
  const effectiveStart = start > workStart ? start : workStart;
  const effectiveEnd = end < workEnd ? end : workEnd;
  
  let normalMs = 0;
  if (effectiveEnd > effectiveStart) {
    normalMs = effectiveEnd - effectiveStart;
    
    // Trá»« giá» nghá»‰ trÆ°a náº¿u cÃ³ giao thoa
    const overlapBreakStart = effectiveStart > breakStart ? effectiveStart : breakStart;
    const overlapBreakEnd = effectiveEnd < breakEnd ? effectiveEnd : breakEnd;
    if (overlapBreakEnd > overlapBreakStart) {
      normalMs -= (overlapBreakEnd - overlapBreakStart);
    }
  }

  // 2. TÃ­nh giá» OT (náº¿u cÃ³ check out sau workEnd vÃ  cÃ³ approvedOT)
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


// Helper gá»­i thÃ´ng bÃ¡o
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
    console.log(`ðŸš€ ÄÃ£ gá»­i Push Notification tá»›i ID ${employeeId}`);
  } catch (err) {
    console.error('âŒ Lá»—i gá»­i Push Notification:', err.message);
  }
}


// --- 4. API QUáº¢N LÃ Lá»ŠCH Há»ŒP (MEETINGS) ---

// API Xuáº¥t Excel
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
      WHERE status = 'approved' AND type = 'LÃ m thÃªm giá»'
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
    const worksheet = workbook.addWorksheet('BÃ¡o cÃ¡o Chi tiáº¿t');
    const summarySheet = workbook.addWorksheet('Tá»•ng há»£p CÃ´ng');

    // Sheet 1: Chi tiáº¿t
    worksheet.columns = [
      { header: 'MÃ£ NV', key: 'code', width: 15 },
      { header: 'Há» tÃªn', key: 'name', width: 25 },
      { header: 'NgÃ y', key: 'date', width: 15 },
      { header: 'Giá» vÃ o', key: 'in', width: 12 },
      { header: 'Giá» ra', key: 'out', width: 12 },
      { header: 'Tá»•ng giá»', key: 'total', width: 12 },
      { header: 'Giá» hÃ nh chÃ­nh', key: 'normal', width: 15 },
      { header: 'Giá» OT', key: 'ot', width: 12 }
    ];
    worksheet.getRow(1).font = { bold: true };

    // Sheet 2: Tá»•ng há»£p
    summarySheet.columns = [
      { header: 'MÃ£ NV', key: 'code', width: 15 },
      { header: 'Há» tÃªn', key: 'name', width: 25 },
      { header: 'Tá»•ng giá» lÃ m', key: 'totalHours', width: 15 },
      { header: 'NgÃ¢n hÃ ng', key: 'bank_name', width: 20 },
      { header: 'Sá»‘ tÃ i khoáº£n', key: 'account_number', width: 20 },
      { header: 'Chá»§ tÃ i khoáº£n', key: 'account_holder', width: 25 }
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

    // 1. Láº¥y dá»¯ liá»‡u cÅ© Ä‘á»ƒ so sÃ¡nh
    const oldRes = await pool.query(`
      SELECT a.*, to_char(check_in_time, 'HH24:MI:SS') as old_in, 
             to_char(check_out_time, 'HH24:MI:SS') as old_out
      FROM attendance a WHERE id = $1
    `, [id]);
    
    if (oldRes.rows.length === 0) return res.status(404).json({ error: 'KhÃ´ng tÃ¬m tháº¥y báº£n ghi' });
    const old = oldRes.rows[0];

    // 2. Cáº­p nháº­t vÃ o DB
    // LÆ°u Ã½: check_in_time vÃ  check_out_time lÃ  TIMESTAMP, cáº§n káº¿t há»£p vá»›i date
    const newIn = `${date} ${check_in}`;
    const newOut = check_out ? `${date} ${check_out}` : null;

    await pool.query(
      'UPDATE attendance SET check_in_time = $1, check_out_time = $2 WHERE id = $3',
      [newIn, newOut, id]
    );

    // 3. Gá»­i Push Notification thÃ´ng bÃ¡o thay Ä‘á»•i
    let changeLog = [];
    if (old.old_in !== check_in) changeLog.push(`Giá» vÃ o: ${old.old_in} âž” ${check_in}`);
    if ((old.old_out || '--:--:--') !== (check_out || '--:--:--')) {
      changeLog.push(`Giá» ra: ${old.old_out || '--:--:--'} âž” ${check_out || '--:--:--'}`);
    }

    if (changeLog.length > 0) {
      const title = 'âš¡ Chá»‰nh sá»­a giá» cÃ´ng';
      const body = `Admin Ä‘Ã£ sá»­a giá» cÃ´ng ngÃ y ${date}:\n${changeLog.join('\n')}`;
      
      await sendPushNotification(
        old.employee_id,
        title,
        body,
        { type: 'attendance_update', date }
      );

      // Emit realtime event Ä‘á»ƒ lÆ°u vÃ o danh sÃ¡ch thÃ´ng bÃ¡o trÃªn App
      io.emit('attendance_edited', {
        employee_id: old.employee_id,
        title: title,
        body: body,
        date: date
      });

      // LÆ°u vÃ o user_notifications
      await pool.query(
        "INSERT INTO user_notifications (employee_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5)",
        [old.employee_id, title, body, 'attendance_update', JSON.stringify({ date })]
      );
    }

    res.json({ success: true });
  } catch (err) { 
    console.error('âŒ Lá»—i sá»­a attendance:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

// --- 6. API PHÃŠ DUYá»†T (APPROVALS) ---
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
  console.log('ðŸ“ Admin gÃ¡n lá»‹ch OT/Nghá»‰:', req.body);
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
      return res.status(400).json({ error: "Vui lÃ²ng chá»n Ä‘á»‘i tÆ°á»£ng gÃ¡n" });
    }

    if (targetEmployees.length === 0) {
      return res.status(404).json({ error: "KhÃ´ng tÃ¬m tháº¥y nhÃ¢n viÃªn phÃ¹ há»£p" });
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
        `Lá»‹ch ${type} má»›i`,
        `Quáº£n trá»‹ viÃªn Ä‘Ã£ xáº¿p lá»‹ch ${type} cho báº¡n: ${reason}`,
        { type: 'approval_assigned', id: approval.id.toString() }
      );
    }

    res.json({ success: true, message: `ÄÃ£ gÃ¡n lá»‹ch cho ${targetEmployees.length} nhÃ¢n viÃªn` });
  } catch (err) {
    console.error('âŒ Lá»—i admin-assign:', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/approvals', async (req, res) => {
  console.log('ðŸ” Truy váº¥n danh sÃ¡ch phÃª duyá»‡t:', req.query);
  try {
    const { employee_id } = req.query;
    let query = 'SELECT * FROM approvals';
    let params = [];
    
    if (employee_id) {
      query += ' WHERE employee_id = $1';
      params.push(employee_id);
    }
    
    const r = await pool.query(query, params);
    
    // Chuáº©n hÃ³a dá»¯ liá»‡u trÆ°á»›c khi gá»­i vá»
    const rows = r.rows.map(row => ({
      ...row,
      from_date: row.from_date ? new Date(row.from_date).toISOString() : null,
      to_date: row.to_date ? new Date(row.to_date).toISOString() : null,
      created_at: row.created_at ? new Date(row.created_at).toISOString() : null,
      reviewed_at: row.reviewed_at ? new Date(row.reviewed_at).toISOString() : null,
      attachment_urls: typeof row.attachment_urls === 'string' ? JSON.parse(row.attachment_urls) : (row.attachment_urls || [])
    }));

    console.log(`âœ… Tráº£ vá» ${rows.length} yÃªu cáº§u cho ID: ${employee_id || 'ALL'}`);
    res.json(rows);
  } catch (err) { 
    console.error('âŒ Lá»—i truy váº¥n approvals:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

app.put('/api/approvals/:id', async (req, res) => {
  try {
    const { status } = req.body;
    // 1. Cáº­p nháº­t tráº¡ng thÃ¡i phÃª duyá»‡t
    const result = await pool.query('UPDATE approvals SET status = $1 WHERE id = $2 RETURNING *', [status, req.params.id]);
    const approval = result.rows[0];
    
    // 2. Náº¿u lÃ  QuÃªn cháº¥m cÃ´ng vÃ  Ä‘Æ°á»£c duyá»‡t -> ThÃªm vÃ o báº£ng attendance NGAY Láº¬P Tá»¨C
    if (status === 'approved' && approval.type === 'QuÃªn cháº¥m cÃ´ng') {
      console.log('ðŸ“ Bá»• sung cháº¥m cÃ´ng tá»« Ä‘Æ¡n quÃªn cháº¥m cÃ´ng cho:', approval.employee_name);
      try {
        const checkIn = new Date(approval.from_date);
        const checkOut = new Date(approval.to_date);
        
        // Äá»‹nh dáº¡ng HH:mm:ss cho cÃ¡c cá»™t varchar náº¿u cáº§n
        const cinStr = `${checkIn.getHours().toString().padStart(2, '0')}:${checkIn.getMinutes().toString().padStart(2, '0')}:${checkIn.getSeconds().toString().padStart(2, '0')}`;
        const coutStr = `${checkOut.getHours().toString().padStart(2, '0')}:${checkOut.getMinutes().toString().padStart(2, '0')}:${checkOut.getSeconds().toString().padStart(2, '0')}`;

        await pool.query(
          'INSERT INTO attendance (employee_id, employee_name, check_in_time, check_out_time, check_in, check_out, check_in_method) VALUES ($1, $2, $3, $4, $5, $6, $7)',
          [approval.employee_id, approval.employee_name, approval.from_date, approval.to_date, cinStr, coutStr, 'Quáº£n trá»‹ viÃªn bá»• sung']
        );
        console.log('âœ… ÄÃ£ chÃ¨n báº£n ghi cháº¥m cÃ´ng má»›i thÃ nh cÃ´ng.');
      } catch (insertErr) {
        console.error('âŒ Lá»—i khi chÃ¨n báº£n ghi cháº¥m cÃ´ng bá»• sung:', insertErr.message);
      }
    }

    // 3. ThÃ´ng bÃ¡o Real-time sau khi Ä‘Ã£ chuáº©n bá»‹ xong dá»¯ liá»‡u
    io.emit('approval_updated', approval);
    io.emit('attendance_updated'); // ThÃ´ng bÃ¡o cho Web Admin cáº­p nháº­t danh sÃ¡ch cháº¥m cÃ´ng


    // Gá»­i Push Notification
    const statusText = status === 'approved' ? 'Ä‘Æ°á»£c PHÃŠ DUYá»†T' : 'bá»‹ Tá»ª CHá»I';
    await sendPushNotification(
      approval.employee_id,
      'Cáº­p nháº­t yÃªu cáº§u',
      `YÃªu cáº§u "${approval.type}" cá»§a báº¡n Ä‘Ã£ ${statusText}.`,
      { type: 'approval', id: approval.id.toString() }
    );

    // LÆ°u vÃ o user_notifications
    await pool.query(
      "INSERT INTO user_notifications (employee_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5)",
      [
        approval.employee_id, 
        'Cáº­p nháº­t yÃªu cáº§u', 
        `YÃªu cáº§u "${approval.type}" cá»§a báº¡n Ä‘Ã£ ${statusText}.`, 
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
      "SELECT COUNT(*) FROM approvals WHERE employee_id = $1 AND type = 'QuÃªn cháº¥m cÃ´ng' AND status != 'rejected' AND to_char(created_at, 'YYYY-MM') = $2",
      [employee_id, month]
    );
    res.json({ count: parseInt(r.rows[0].count) });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/overtimes', async (req, res) => {
  console.log('ðŸ“¥ Nháº­n yÃªu cáº§u OT má»›i:', req.body);
  try {
    const { employee_id, employee_name, date, hours, reason } = req.body;
    const result = await pool.query(
      'INSERT INTO approvals (employee_id, employee_name, type, reason, from_date, to_date, total_hours, status) VALUES ($1, $2, \'LÃ m thÃªm giá»\', $3, $4, $4, $5, \'pending\') RETURNING *',
      [employee_id, employee_name, reason, date, hours]
    );
    console.log('âœ… ÄÃ£ lÆ°u Ä‘Æ¡n OT vÃ o DB:', result.rows[0].id);
    io.emit('new_approval', result.rows[0]);
    res.json(result.rows[0]);
  } catch (err) { 
    console.error('âŒ Lá»—i lÆ°u Ä‘Æ¡n OT:', err.message);
    res.status(500).json({ error: err.message }); 
  }
});

// --- 7. API THá»NG KÃŠ (STATISTICS) ---
app.get('/api/statistics/:employeeId', async (req, res) => {
  const { employeeId } = req.params;
  const { period, start_date, end_date } = req.query; // 'week', 'month', 'year' hoáº·c khoáº£ng ngÃ y cá»¥ thá»ƒ
  
  try {
    // 1. Láº¥y dá»¯ liá»‡u Ä‘iá»ƒm danh
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

    // 2. Láº¥y cáº¥u hÃ¬nh vÃ  OT Ä‘á»ƒ tÃ­nh toÃ¡n
    const configRes = await pool.query('SELECT * FROM company_config LIMIT 1');
    const config = configRes.rows[0];

    const otRes = await pool.query(`
      SELECT to_char(from_date, 'YYYY-MM-DD') as date, SUM(total_hours) as hours
      FROM approvals 
      WHERE employee_id = $1 AND status = 'approved' AND type = 'LÃ m thÃªm giá»'
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
      
      // GÃ¡n OT vÃ o tá»«ng dÃ²ng Ä‘á»ƒ tráº£ vá» cho App hiá»ƒn thá»‹ á»Ÿ má»¥c Lá»‹ch sá»­
      row.ot_hours = approvedOT;
      
      // Kiá»ƒm tra Ä‘i muá»™n (So vá»›i work_start_time trong config)
      const checkInHour = new Date(row.check_in_time).getHours();
      const checkInMin = new Date(row.check_in_time).getMinutes();
      const [limitHour, limitMin] = (config.work_start_time || '08:30').split(':').map(Number);
      
      if (checkInHour > limitHour || (checkInHour === limitHour && checkInMin > limitMin)) {
        lateDays++;
      }
    });

    // 3. Láº¥y sá»‘ ngÃ y nghá»‰ tá»« approvals (Xá»­ lÃ½ dá»¯ liá»‡u lá»—i/ngÆ°á»£c ngÃ y)
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
       AND type != 'Làm thêm giờ'
       AND type NOT LIKE '%thêm%'`,
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

// Lá»‹ch sá»­ AI riÃªng
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
  if (!req.file) return res.status(400).json({ error: 'KhÃ´ng cÃ³ tá»‡p nÃ o Ä‘Æ°á»£c táº£i lÃªn.' });
  res.json({
    file_url: `/uploads/chat/${req.file.filename}`,
    file_name: req.file.originalname,
    file_type: req.file.mimetype
  });
});

// Lá»‹ch sá»­ Admin riÃªng (cho Flutter app)
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

// Lá»‹ch sá»­ chat theo userId (cho Web Admin dÃ¹ng)
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
    res.json({ message: 'ÄÃ£ xÃ³a toÃ n bá»™ lá»‹ch sá»­ chat.' });
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
    
    // LÆ°u cÃ¢u há»i cá»§a user (chat_type='ai')
    await pool.query(
      "INSERT INTO chat_messages (sender_id, message, is_ai, chat_type) VALUES ($1, $2, false, 'ai')",
      [userId, message]
    );

    const bot = new HybridChatbot(pool);
    const result = await bot.processMessage(userId, message);
    const reply = result.text;

    // LÆ°u cÃ¢u tráº£ lá»i AI (chat_type='ai', is_ai=true)
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
    console.error('âŒ Lá»—i AI Chat:', err.message);
    res.status(500).json({ error: err.message, reply: "Xin lá»—i, tÃ´i Ä‘ang gáº·p sá»± cá»‘. Vui lÃ²ng thá»­ láº¡i hoáº·c chat vá»›i Admin.", suggestAdmin: true, suggestions: ['Thá»­ láº¡i'], source: 'system' }); 
  }
});

// Láº¥y danh sÃ¡ch há»™i thoáº¡i cá»§a user
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

app.put('/api/conversations/:id/read', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;
    if (!userId) return res.status(400).json({ error: 'Missing userId' });
    
    await pool.query(
      `UPDATE conversation_members SET last_read_at = NOW() WHERE conversation_id = $1 AND user_id = $2`,
      [id, userId]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
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

// Táº¡o nhÃ³m má»›i
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

// Láº¥y Ä‘á»“ng nghiá»‡p (trá»« admin)
app.get('/api/users/colleagues', async (req, res) => {
  try {
    const { userId } = req.query;
    const r = await pool.query("SELECT id, name as full_name, department_name as department FROM employees WHERE id != $1 AND role != 'admin'", [userId]);
    res.json(r.rows);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Láº¥y nhá»¯ng ngÆ°á»i Ä‘Ã£ tá»«ng chat 1-1 (Ä‘á»ƒ gá»£i Ã½ táº¡o nhÃ³m má»›i)
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

// --- KHá»žI CHáº Y SERVER ---
const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`ðŸš€ WorkMate Server is clean and running on port ${PORT} (0.0.0.0)`);
});
