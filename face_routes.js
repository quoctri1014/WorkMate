// ============================================================
// face_routes.js
// Backend Node.js (Express + PostgreSQL)
// API đăng ký & chấm công bằng khuôn mặt
// ============================================================

const express = require('express');
const router = express.Router();

// pool là pg.Pool đã kết nối sẵn — import từ db.js của bạn
// Ví dụ: const pool = require('../db');

// ------------------------------------------------------------------
// Utility: Tính khoảng cách Euclidean giữa 2 embedding (server-side)
// Dùng khi muốn so sánh phía server thay vì client
// ------------------------------------------------------------------

/**
 * Tính khoảng cách Euclidean giữa 2 vector embedding.
 * @param {number[]} a - Embedding thứ nhất
 * @param {number[]} b - Embedding thứ hai
 * @returns {number} Khoảng cách (< 0.7 = khớp)
 */
function euclideanDistance(a, b) {
  if (a.length !== b.length) {
    throw new Error(`Kích thước embedding khác nhau: ${a.length} vs ${b.length}`);
  }
  let sum = 0;
  for (let i = 0; i < a.length; i++) {
    const diff = a[i] - b[i];
    sum += diff * diff;
  }
  return Math.sqrt(sum);
}

const MATCH_THRESHOLD = 0.70; // Ngưỡng khớp khuôn mặt

// ------------------------------------------------------------------
// Migration: Thêm cột face_embedding vào bảng employees
// Chạy lệnh SQL này 1 lần trong database của bạn:
// ALTER TABLE employees ADD COLUMN IF NOT EXISTS face_embedding JSONB;
// ------------------------------------------------------------------

// ------------------------------------------------------------------
// POST /api/face/register
// Đăng ký khuôn mặt cho nhân viên
// Body: { employee_id: number, embedding: number[] }
// ------------------------------------------------------------------

router.post('/register', async (req, res) => {
  const { employee_id, embedding } = req.body;

  // Validate đầu vào
  if (!employee_id || !Array.isArray(embedding)) {
    return res.status(400).json({
      success: false,
      message: 'Thiếu employee_id hoặc embedding không hợp lệ.',
    });
  }

  if (embedding.length !== 192) {
    return res.status(400).json({
      success: false,
      message: `Embedding phải có 192 chiều, nhận được ${embedding.length}.`,
    });
  }

  try {
    // Kiểm tra nhân viên tồn tại
    const empResult = await pool.query(
      'SELECT id, name FROM employees WHERE id = $1',
      [employee_id]
    );

    if (empResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Không tìm thấy nhân viên ID = ${employee_id}.`,
      });
    }

    // Lưu embedding vào DB
    await pool.query(
      `UPDATE employees
       SET face_embedding = $1,
           face_registered_at = NOW()
       WHERE id = $2`,
      [JSON.stringify(embedding), employee_id]
    );

    return res.json({
      success: true,
      message: 'Đăng ký khuôn mặt thành công.',
      employee: {
        id: employee_id,
        name: empResult.rows[0].name,
      },
    });
  } catch (error) {
    console.error('[FaceAPI] Lỗi đăng ký khuôn mặt:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server. Vui lòng thử lại.',
    });
  }
});

// ------------------------------------------------------------------
// POST /api/face/checkin
// Chấm công bằng khuôn mặt
// Body: { employee_id: number, embedding: number[] }
//
// Luồng:
// 1. Lấy embedding đã lưu từ DB
// 2. So sánh Euclidean distance
// 3. Nếu khớp -> ghi nhận chấm công
// ------------------------------------------------------------------

router.post('/checkin', async (req, res) => {
  const { employee_id, embedding } = req.body;

  if (!employee_id || !Array.isArray(embedding)) {
    return res.status(400).json({
      success: false,
      message: 'Thiếu employee_id hoặc embedding.',
    });
  }

  try {
    // 1. Lấy embedding đã lưu
    const empResult = await pool.query(
      `SELECT id, name, face_embedding
       FROM employees
       WHERE id = $1`,
      [employee_id]
    );

    if (empResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy nhân viên.',
      });
    }

    const employee = empResult.rows[0];

    if (!employee.face_embedding) {
      return res.status(400).json({
        success: false,
        message: 'Nhân viên chưa đăng ký khuôn mặt.',
      });
    }

    // 2. Parse embedding đã lưu
    const savedEmbedding = typeof employee.face_embedding === 'string'
      ? JSON.parse(employee.face_embedding)
      : employee.face_embedding;

    // 3. So sánh khoảng cách
    const distance = euclideanDistance(embedding, savedEmbedding);
    const isMatch = distance < MATCH_THRESHOLD;
    const confidence = Math.max(
      0,
      ((1 - distance / MATCH_THRESHOLD) * 100)
    ).toFixed(1);

    if (!isMatch) {
      // Ghi log thất bại (tuỳ chọn)
      await pool.query(
        `INSERT INTO attendance_logs (employee_id, status, confidence, distance, created_at)
         VALUES ($1, 'FACE_MISMATCH', $2, $3, NOW())`,
        [employee_id, confidence, distance]
      ).catch(() => {}); // Không throw nếu bảng chưa có

      return res.status(403).json({
        success: false,
        isMatch: false,
        distance: +distance.toFixed(4),
        confidence: +confidence,
        message: 'Khuôn mặt không khớp. Vui lòng thử lại.',
      });
    }

    // 4. Ghi nhận chấm công
    const now = new Date();
    const today = now.toISOString().split('T')[0]; // YYYY-MM-DD

    // Kiểm tra đã chấm công hôm nay chưa
    const existingCheckin = await pool.query(
      `SELECT id, check_in_time FROM attendance
       WHERE employee_id = $1
         AND DATE(check_in_time) = $2
       ORDER BY check_in_time DESC
       LIMIT 1`,
      [employee_id, today]
    );

    let attendanceRecord;

    if (existingCheckin.rows.length === 0) {
      // Chấm công vào
      const insertResult = await pool.query(
        `INSERT INTO attendance (employee_id, check_in_time, check_in_method, face_confidence)
         VALUES ($1, NOW(), 'FACE_ID', $2)
         RETURNING *`,
        [employee_id, confidence]
      );
      attendanceRecord = insertResult.rows[0];
    } else {
      // Chấm công ra (nếu chưa có check_out_time)
      const existing = existingCheckin.rows[0];
      if (!existing.check_out_time) {
        const updateResult = await pool.query(
          `UPDATE attendance
           SET check_out_time = NOW(), check_out_face_confidence = $1
           WHERE id = $2
           RETURNING *`,
          [confidence, existing.id]
        );
        attendanceRecord = updateResult.rows[0];
      } else {
        attendanceRecord = existing;
      }
    }

    return res.json({
      success: true,
      isMatch: true,
      distance: +distance.toFixed(4),
      confidence: +confidence,
      employee: {
        id: employee.id,
        name: employee.name,
      },
      attendance: attendanceRecord,
      message: `Chấm công thành công! Độ chính xác: ${confidence}%`,
    });
  } catch (error) {
    console.error('[FaceAPI] Lỗi chấm công:', error);
    return res.status(500).json({
      success: false,
      message: 'Lỗi server. Vui lòng thử lại.',
    });
  }
});

// ------------------------------------------------------------------
// GET /api/face/embedding/:employee_id
// App Flutter gọi để lấy embedding đã lưu (dùng khi so sánh client-side)
// ------------------------------------------------------------------

router.get('/embedding/:employee_id', async (req, res) => {
  const { employee_id } = req.params;

  try {
    const result = await pool.query(
      'SELECT face_embedding FROM employees WHERE id = $1',
      [employee_id]
    );

    if (result.rows.length === 0 || !result.rows[0].face_embedding) {
      return res.status(404).json({
        success: false,
        message: 'Chưa có dữ liệu khuôn mặt.',
      });
    }

    const embedding = typeof result.rows[0].face_embedding === 'string'
      ? JSON.parse(result.rows[0].face_embedding)
      : result.rows[0].face_embedding;

    return res.json({ success: true, embedding });
  } catch (error) {
    console.error('[FaceAPI] Lỗi lấy embedding:', error);
    return res.status(500).json({ success: false, message: 'Lỗi server.' });
  }
});

// ------------------------------------------------------------------
// DELETE /api/face/reset/:employee_id
// Xoá khuôn mặt (để đăng ký lại)
// ------------------------------------------------------------------

router.delete('/reset/:employee_id', async (req, res) => {
  const { employee_id } = req.params;

  try {
    await pool.query(
      'UPDATE employees SET face_embedding = NULL, face_registered_at = NULL WHERE id = $1',
      [employee_id]
    );
    return res.json({ success: true, message: 'Đã xoá dữ liệu khuôn mặt.' });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Lỗi server.' });
  }
});

module.exports = router;

// ------------------------------------------------------------------
// Đăng ký routes trong app.js / server.js của bạn:
//
// const faceRoutes = require('./routes/face_routes');
// app.use('/api/face', faceRoutes);
//
// SQL Migration cần chạy:
//
// ALTER TABLE employees
//   ADD COLUMN IF NOT EXISTS face_embedding JSONB,
//   ADD COLUMN IF NOT EXISTS face_registered_at TIMESTAMPTZ;
//
// CREATE TABLE IF NOT EXISTS attendance_logs (
//   id SERIAL PRIMARY KEY,
//   employee_id INT REFERENCES employees(id),
//   status VARCHAR(50),
//   confidence NUMERIC(5,2),
//   distance NUMERIC(8,4),
//   created_at TIMESTAMPTZ DEFAULT NOW()
// );
// ------------------------------------------------------------------
