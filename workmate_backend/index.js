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
      io.emit('online_users', Array.from(new Set(onlineUsers.values())));
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

// Cấu hình Multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = './uploads';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage });

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

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
const MATCH_THRESHOLD = 1.5; // Tăng lên 1.5 cực kỳ thoải mái để test

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
      
      CREATE TABLE IF NOT EXISTS employee_banks (
        id SERIAL PRIMARY KEY,
        employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
        bank_name VARCHAR(255) NOT NULL,
        account_number VARCHAR(50) NOT NULL,
        account_holder VARCHAR(255) NOT NULL,
        is_default BOOLEAN DEFAULT FALSE,
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
    
    if (is_online) {
      meet_link = `https://meet.google.com/${Math.random().toString(36).slice(3,6)}-${Math.random().toString(36).slice(3,7)}-${Math.random().toString(36).slice(3,6)}`;
    }

    const result = await pool.query(
      'INSERT INTO meetings (title, content, department_ids, start_time, location, is_online) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [title, content, JSON.stringify(department_ids), start_time, meet_link, is_online]
    );

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
  const { employee_id, embedding } = req.body;
  try {
    await pool.query(
      'UPDATE employees SET face_embedding = $1, face_registered_at = NOW() WHERE id = $2',
      [JSON.stringify(embedding), employee_id]
    );
    res.json({ success: true, message: "Đăng ký thành công" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

app.get('/api/face/embedding/:id', async (req, res) => {
  try {
    const r = await pool.query('SELECT face_embedding FROM employees WHERE id = $1', [req.params.id]);
    if (r.rows.length === 0 || !r.rows[0].face_embedding) return res.status(404).json({ message: "Chưa có dữ liệu" });
    const embedding = typeof r.rows[0].face_embedding === 'string' ? JSON.parse(r.rows[0].face_embedding) : r.rows[0].face_embedding;
    res.json({ success: true, embedding });
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
  const { employee_id, embedding, lat, lng, wifi_ssid } = req.body;
  try {
    // 1. Lấy cấu hình Safe Zone
    const configResult = await pool.query('SELECT * FROM company_config LIMIT 1');
    const config = configResult.rows[0];

    // 2. Kiểm tra WiFi (Nếu có cấu hình)
    if (config && config.safe_wifi_ssid && wifi_ssid !== config.safe_wifi_ssid) {
      return res.status(403).json({ success: false, message: `Vui lòng kết nối WiFi: ${config.safe_wifi_ssid}` });
    }

    // 3. Kiểm tra GPS (Nếu có cấu hình)
    if (config && config.safe_lat && config.safe_lng) {
      const distance = getDistance(lat, lng, config.safe_lat, config.safe_lng);
      if (distance > config.radius_meters) {
        return res.status(403).json({ success: false, message: `Bạn đang ở ngoài vùng cho phép (${Math.round(distance)}m)` });
      }
    }

    // 4. Kiểm tra khuôn mặt
    const r = await pool.query('SELECT face_embedding FROM employees WHERE id = $1', [employee_id]);
    if (r.rows.length === 0 || !r.rows[0].face_embedding) return res.status(400).json({ message: "Chưa đăng ký khuôn mặt" });
    
    const saved = typeof r.rows[0].face_embedding === 'string' ? JSON.parse(r.rows[0].face_embedding) : r.rows[0].face_embedding;
    const dist = euclideanDistance(embedding, saved);
    const isMatch = dist < MATCH_THRESHOLD;

    if (!isMatch) return res.status(403).json({ success: false, message: "Khuôn mặt không khớp" });

    const today = new Date().toISOString().split('T')[0];
    const existing = await pool.query('SELECT * FROM attendance WHERE employee_id = $1 AND DATE(check_in_time) = $2', [employee_id, today]);

    if (existing.rows.length === 0) {
      const result = await pool.query('INSERT INTO attendance (employee_id, check_in_time, check_in_method) VALUES ($1, NOW(), \'FACE_ID\') RETURNING *', [employee_id]);
      io.emit('new_attendance', result.rows[0]);
    } else if (!existing.rows[0].check_out_time) {
      const result = await pool.query('UPDATE attendance SET check_out_time = NOW() WHERE id = $1 RETURNING *', [existing.rows[0].id]);
      io.emit('attendance_updated', result.rows[0]);
    }

    res.json({ success: true, message: "Chấm công thành công" });
  } catch (err) {
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
  const { company_name, safe_lat, safe_lng, safe_wifi_ssid, safe_wifi_bssid, radius_meters } = req.body;
  try {
    const existing = await pool.query('SELECT id FROM company_config LIMIT 1');
    if (existing.rows.length > 0) {
      const r = await pool.query(
        'UPDATE company_config SET company_name = $1, safe_lat = $2, safe_lng = $3, safe_wifi_ssid = $4, safe_wifi_bssid = $5, radius_meters = $6 WHERE id = $7 RETURNING *',
        [company_name, safe_lat, safe_lng, safe_wifi_ssid, safe_wifi_bssid, radius_meters, existing.rows[0].id]
      );
      res.json(r.rows[0]);
    } else {
      const r = await pool.query(
        'INSERT INTO company_config (company_name, safe_lat, safe_lng, safe_wifi_ssid, safe_wifi_bssid, radius_meters) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [company_name, safe_lat, safe_lng, safe_wifi_ssid, safe_wifi_bssid, radius_meters]
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
  try {
    const { name, code, positions } = req.body;
    const r = await pool.query(
      'INSERT INTO departments (name, code, positions) VALUES ($1, $2, $3) RETURNING *',
      [name, code, positions]
    );
    res.json(r.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
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


// --- 4. API QUẢN LÝ LỊCH HỌP (MEETINGS) ---

app.get('/api/attendance', async (req, res) => {
  try {
    const r = await pool.query('SELECT * FROM attendance ORDER BY created_at DESC');
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
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
    const result = await pool.query('UPDATE approvals SET status = $1 WHERE id = $2 RETURNING *', [status, req.params.id]);
    io.emit('approval_updated', result.rows[0]);
    res.json(result.rows[0]);
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

    // 2. Tính toán các chỉ số
    let totalNormalHours = 0;
    let totalOTHours = 0;
    let lateDays = 0;
    
    // Giả sử làm việc từ thứ 2 đến chủ nhật (7 ngày gần nhất cho biểu đồ tuần)
    const weeklyData = Array(7).fill(0).map(() => ({ normal: 0, ot: 0, deficiency: 0 }));
    const now = new Date();
    
    attendance.rows.forEach(row => {
      if (row.check_out_time) {
        const duration = (new Date(row.check_out_time) - new Date(row.check_in_time)) / (1000 * 60 * 60);
        let normal = duration > 8 ? 8 : duration;
        let ot = duration > 8 ? duration - 8 : 0;
        
        totalNormalHours += normal;
        totalOTHours += ot;

        // Phân bổ vào biểu đồ tuần (0: Thứ 2, ..., 6: Chủ nhật)
        const dayIdx = (new Date(row.check_in_time).getDay() + 6) % 7;
        if (duration >= 8) {
          weeklyData[dayIdx].normal = 8;
          weeklyData[dayIdx].ot = ot;
        } else {
          weeklyData[dayIdx].deficiency = duration;
        }
      }
      
      // Kiểm tra đi muộn (Giả sử quy định là 8:30)
      const checkInHour = new Date(row.check_in_time).getHours();
      const checkInMin = new Date(row.check_in_time).getMinutes();
      if (checkInHour > 8 || (checkInHour === 8 && checkInMin > 30)) {
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

// --- KHỞI CHẠY SERVER ---
server.listen(5000, '0.0.0.0', () => {
  console.log('🚀 WorkMate Server is clean and running on port 5000 (0.0.0.0)');
});
