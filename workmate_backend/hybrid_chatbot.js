class HybridChatbot {
  constructor(db) {
    this.db = db;
    this.unknownCount = {};

    this.intents = {
      // Chấm công
      attendance_today: {
        keywords: ['hôm nay chấm công', 'chấm công chưa', 'vào ca chưa', 'điểm danh', 'check in'],
        handler: 'handleAttendanceToday'
      },
      attendance_history: {
        keywords: ['lịch sử chấm công', 'chấm công tuần', 'chấm công tháng', 'bao nhiêu buổi', 'đi làm mấy ngày'],
        handler: 'handleAttendanceHistory'
      },
      late_record: {
        keywords: ['đi trễ', 'muộn', 'trễ mấy lần'],
        handler: 'handleLateRecord'
      },

      // Đơn từ / Phê duyệt
      my_approvals: {
        keywords: ['đơn từ', 'đơn của tôi', 'yêu cầu của tôi', 'trạng thái đơn', 'đơn phê duyệt', 'đơn xin'],
        handler: 'handleMyApprovals'
      },
      request_leave: {
        keywords: ['xin nghỉ', 'muốn nghỉ', 'nghỉ phép', 'tạo đơn nghỉ'],
        handler: 'handleRequestLeave'
      },
      request_overtime: {
        keywords: ['đăng ký tăng ca', 'làm thêm giờ', 'xin tăng ca', 'ot'],
        handler: 'handleRequestOvertime'
      },

      // Thống kê
      my_stats: {
        keywords: ['thống kê', 'tổng giờ làm', 'bao nhiêu giờ', 'số giờ', 'hiệu suất'],
        handler: 'handleMyStats'
      },
      remaining_leave: {
        keywords: ['còn mấy ngày phép', 'phép còn lại', 'bao nhiêu phép', 'số ngày phép'],
        handler: 'handleRemainingLeave'
      },

      // Đồng nghiệp / Phòng ban
      team_info: {
        keywords: ['đồng nghiệp', 'team', 'phòng ban', 'ai trong nhóm', 'cùng phòng'],
        handler: 'handleTeamInfo'
      },
      find_colleague: {
        keywords: ['tìm nhân viên', 'email của', 'liên hệ', 'thông tin nhân viên'],
        handler: 'handleFindColleague'
      },

      // Lịch họp
      meetings: {
        keywords: ['lịch họp', 'cuộc họp', 'họp hôm nay', 'họp tuần này', 'meeting'],
        handler: 'handleMeetings'
      },

      // Thông tin cá nhân
      my_profile: {
        keywords: ['thông tin của tôi', 'hồ sơ', 'profile', 'mã nhân viên', 'tôi là ai'],
        handler: 'handleMyProfile'
      },

      // Nội quy / Chính sách
      policy_overtime: {
        keywords: ['chính sách tăng ca', 'quy định tăng ca', 'phụ cấp tăng ca'],
        handler: 'handlePolicyOvertime'
      },
      policy_work: {
        keywords: ['giờ làm việc', 'ca làm', 'lịch làm', 'giờ vào', 'giờ ra'],
        handler: 'handlePolicyWork'
      },

      // Chào hỏi
      greeting: {
        keywords: ['xin chào', 'hello', 'hi', 'chào bot', 'ơi', 'chào bạn', 'hey'],
        handler: 'handleGreeting'
      },
      thanks: {
        keywords: ['cảm ơn', 'thank', 'tks', 'cám ơn'],
        handler: 'handleThanks'
      },
      connect_admin: {
        keywords: ['gặp admin', 'nói chuyện admin', 'kết nối hỗ trợ', 'cần giúp đỡ', 'chat admin'],
        handler: 'handleConnectAdmin'
      },

      // Tính năng app
      how_to_checkin: {
        keywords: ['cách chấm công', 'chấm công bằng gì', 'face id', 'nhận diện khuôn mặt', 'quét mặt'],
        handler: 'handleHowToCheckin'
      },
      how_to_qr: {
        keywords: ['quét qr', 'mã qr', 'qr code', 'quét mã'],
        handler: 'handleHowToQR'
      },
    };
  }

  detectIntent(message) {
    const msg = message.toLowerCase().trim();
    for (const [name, config] of Object.entries(this.intents)) {
      if (config.keywords.some(kw => msg.includes(kw))) return name;
    }
    return null;
  }

  async processMessage(userId, message) {
    const intent = this.detectIntent(message);
    if (intent) {
      this.unknownCount[userId] = 0;
      const handler = this.intents[intent].handler;
      if (this[handler]) return await this[handler](userId, message);
    }

    this.unknownCount[userId] = (this.unknownCount[userId] || 0) + 1;
    if (this.unknownCount[userId] >= 2) {
      this.unknownCount[userId] = 0;
      return {
        text: '😅 Câu hỏi này nằm ngoài khả năng của tôi.\nBạn có muốn nhắn tin trực tiếp cho Admin không?',
        suggestions: ['Kết nối Admin', 'Hôm nay chấm công chưa?', 'Xem thống kê'],
        action: 'open_admin_chat', source: 'rule'
      };
    }
    return {
      text: '🤔 Tôi chưa hiểu rõ ý bạn. Bạn có thể thử hỏi về:\n• Chấm công\n• Đơn từ & Phê duyệt\n• Thống kê giờ làm\n• Lịch họp\n• Đồng nghiệp cùng phòng',
      suggestions: ['Hôm nay chấm công chưa?', 'Xem đơn từ của tôi', 'Còn mấy ngày phép?', 'Lịch họp hôm nay', 'Đồng nghiệp cùng phòng'],
      source: 'bot'
    };
  }

  // ── CHẤM CÔNG ──
  async handleAttendanceToday(userId) {
    try {
      const r = await this.db.query(
        `SELECT check_in_time, check_out_time, check_in_method FROM attendance
         WHERE employee_id=$1 AND DATE(check_in_time AT TIME ZONE 'Asia/Ho_Chi_Minh')=CURRENT_DATE
         ORDER BY check_in_time DESC LIMIT 1`, [userId]
      );
      if (!r.rows.length) return {
        text: '⚠️ Hôm nay bạn chưa chấm công!\nHãy vào trang chủ và chấm công bằng Face ID nhé.',
        suggestions: ['Cách chấm công bằng Face ID', 'Xem thống kê', 'Chat Admin']
      };
      const { check_in_time, check_out_time, check_in_method } = r.rows[0];
      const inTime = new Date(check_in_time).toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'});
      const outTime = check_out_time ? new Date(check_out_time).toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'}) : 'Chưa checkout';
      return {
        text: `✅ Chấm công hôm nay:\n• Vào: ${inTime}\n• Ra: ${outTime}\n• Phương thức: ${check_in_method || 'Face ID'}`,
        suggestions: ['Xem thống kê tuần', 'Đi trễ mấy lần?', 'Còn mấy ngày phép?']
      };
    } catch(e) { return this._error(); }
  }

  async handleAttendanceHistory(userId) {
    try {
      const r = await this.db.query(
        `SELECT COUNT(*) as total,
                COUNT(CASE WHEN check_out_time IS NOT NULL THEN 1 END) as completed
         FROM attendance WHERE employee_id=$1 
         AND check_in_time >= date_trunc('month', NOW())`, [userId]
      );
      const { total, completed } = r.rows[0];
      return {
        text: `📊 Chấm công tháng này:\n• Tổng số buổi: ${total}\n• Đã checkout: ${completed}\n• Chưa checkout: ${total - completed}\n\nĐể xem chi tiết, vào tab Thống Kê trên app nhé.`,
        suggestions: ['Đi trễ mấy lần?', 'Xem thống kê', 'Hôm nay chấm công chưa?']
      };
    } catch(e) { return this._error(); }
  }

  async handleLateRecord(userId) {
    try {
      const configRes = await this.db.query('SELECT work_start_time FROM company_config LIMIT 1');
      const startTime = configRes.rows[0]?.work_start_time || '08:30';
      const [lh, lm] = startTime.split(':').map(Number);
      const r = await this.db.query(
        `SELECT check_in_time FROM attendance WHERE employee_id=$1 AND check_in_time >= date_trunc('month', NOW())`, [userId]
      );
      let late = 0;
      r.rows.forEach(row => {
        const d = new Date(row.check_in_time);
        if (d.getHours() > lh || (d.getHours() === lh && d.getMinutes() > lm)) late++;
      });
      return {
        text: `⏰ Tháng này bạn đi trễ ${late} lần.\n${late > 3 ? '⚠️ Hãy chú ý giờ giấc nhé!' : '✅ Tốt lắm, tiếp tục phát huy!'}\n\nGiờ vào quy định: ${startTime}`,
        suggestions: ['Xem thống kê', 'Hôm nay chấm công chưa?', 'Giờ làm việc']
      };
    } catch(e) { return this._error(); }
  }

  // ── ĐƠN TỪ / PHÊ DUYỆT ──
  async handleMyApprovals(userId) {
    try {
      const r = await this.db.query(
        `SELECT type, status, created_at FROM approvals WHERE employee_id=$1 ORDER BY created_at DESC LIMIT 5`, [userId]
      );
      if (!r.rows.length) return {
        text: '📋 Bạn chưa có đơn từ nào.\nBạn có thể tạo đơn nghỉ phép hoặc đơn tăng ca trong tab Đơn Từ trên app.',
        suggestions: ['Cách tạo đơn nghỉ phép', 'Cách đăng ký tăng ca', 'Xem thống kê']
      };
      const statusMap = { pending: '⏳ Chờ duyệt', approved: '✅ Đã duyệt', rejected: '❌ Từ chối' };
      const list = r.rows.map(d => {
        const date = new Date(d.created_at).toLocaleDateString('vi-VN');
        return `• ${d.type} (${date}) — ${statusMap[d.status] || d.status}`;
      }).join('\n');
      return {
        text: `📋 5 đơn gần nhất của bạn:\n${list}`,
        suggestions: ['Còn mấy ngày phép?', 'Xem thống kê', 'Hôm nay chấm công chưa?']
      };
    } catch(e) { return this._error(); }
  }

  async handleRequestLeave() {
    return {
      text: '📝 Để tạo đơn nghỉ phép:\n1️⃣ Vào tab "Đơn Từ" trên thanh điều hướng\n2️⃣ Nhấn nút "+" để tạo đơn mới\n3️⃣ Chọn loại "Nghỉ phép"\n4️⃣ Điền ngày và lý do\n5️⃣ Nhấn "Gửi" để chờ Admin phê duyệt',
      suggestions: ['Còn mấy ngày phép?', 'Xem đơn từ của tôi', 'Chat Admin']
    };
  }

  async handleRequestOvertime() {
    return {
      text: '⏱️ Để đăng ký tăng ca:\n1️⃣ Vào tab "Đơn Từ" > "Tăng ca"\n2️⃣ Chọn ngày và số giờ OT\n3️⃣ Điền lý do tăng ca\n4️⃣ Nhấn "Gửi" để chờ Admin phê duyệt\n\n💰 Phụ cấp: Ngày thường x1.5, Cuối tuần x2.0',
      suggestions: ['Chính sách tăng ca', 'Xem đơn từ của tôi', 'Xem thống kê']
    };
  }

  // ── THỐNG KÊ ──
  async handleMyStats(userId) {
    try {
      const r = await this.db.query(
        `SELECT COUNT(*) as days,
                SUM(EXTRACT(EPOCH FROM (COALESCE(check_out_time, check_in_time) - check_in_time))/3600) as hours
         FROM attendance WHERE employee_id=$1 
         AND check_in_time >= date_trunc('month', NOW())`, [userId]
      );
      const days = r.rows[0].days || 0;
      const hours = parseFloat(r.rows[0].hours || 0).toFixed(1);
      return {
        text: `📊 Thống kê tháng này:\n• Số buổi đi làm: ${days}\n• Tổng giờ làm: ${hours}h\n\nĐể xem biểu đồ chi tiết, vào tab "Thống Kê" trên app nhé.`,
        suggestions: ['Đi trễ mấy lần?', 'Còn mấy ngày phép?', 'Hôm nay chấm công chưa?']
      };
    } catch(e) { return this._error(); }
  }

  async handleRemainingLeave(userId) {
    try {
      const r = await this.db.query(
        `SELECT COALESCE(SUM(
          CASE WHEN total_hours > 0 THEN total_hours
               WHEN is_half_day = true THEN 4
               ELSE GREATEST(1, ABS(DATE_PART('day', to_date::timestamp - from_date::timestamp)) + 1) * 8
          END
        ), 0) as used_hours
        FROM approvals WHERE employee_id::text = $1::text 
        AND status IN ('approved','pending')
        AND (LOWER(type) LIKE '%nghỉ%' OR LOWER(type) LIKE '%phép%')
        AND LOWER(type) NOT LIKE '%thêm%'`, [userId]
      );
      const usedHours = parseFloat(r.rows[0].used_hours);
      const remaining = Math.max(0, 12 - (usedHours / 8));
      return {
        text: `🏖️ Phép năm của bạn:\n• Tổng phép: 12 ngày/năm\n• Đã sử dụng: ${(usedHours/8).toFixed(1)} ngày\n• Còn lại: ${remaining.toFixed(1)} ngày`,
        suggestions: ['Cách tạo đơn nghỉ phép', 'Xem đơn từ của tôi', 'Xem thống kê']
      };
    } catch(e) { return this._error(); }
  }

  // ── ĐỒNG NGHIỆP ──
  async handleTeamInfo(userId) {
    try {
      const r = await this.db.query(
        `SELECT u2.name, u2.position, u2.email
         FROM employees u1 JOIN employees u2 ON u1.department_id = u2.department_id
         WHERE u1.id=$1 AND u2.id != $1 AND u2.role != 'admin'
         ORDER BY u2.name LIMIT 10`, [userId]
      );
      if (!r.rows.length) return {
        text: '👥 Phòng ban của bạn chưa có đồng nghiệp nào khác.',
        suggestions: ['Thông tin của tôi', 'Lịch họp hôm nay', 'Chat Admin']
      };
      const list = r.rows.map(m => `• ${m.name} — ${m.position || 'Nhân viên'}`).join('\n');
      return {
        text: `👥 Đồng nghiệp cùng phòng:\n${list}`,
        suggestions: ['Thông tin của tôi', 'Lịch họp', 'Hôm nay chấm công chưa?']
      };
    } catch(e) { return this._error(); }
  }

  async handleFindColleague(userId, message) {
    try {
      const words = message.toLowerCase().replace(/tìm nhân viên|email của|liên hệ|thông tin/g, '').trim();
      if (words.length < 2) return {
        text: 'Bạn muốn tìm ai? Hãy nhập tên nhân viên, ví dụ: "Tìm nhân viên Nguyễn Văn A"',
        suggestions: ['Đồng nghiệp cùng phòng', 'Chat Admin']
      };
      const r = await this.db.query(
        `SELECT name, email, phone, position, department_name FROM employees
         WHERE LOWER(name) LIKE $1 AND role != 'admin' LIMIT 5`, [`%${words}%`]
      );
      if (!r.rows.length) return {
        text: `❌ Không tìm thấy nhân viên "${words}".\nBạn có thể quét mã QR của đồng nghiệp để xem thông tin nhanh.`,
        suggestions: ['Cách quét mã QR', 'Đồng nghiệp cùng phòng', 'Chat Admin']
      };
      const list = r.rows.map(m => `• ${m.name}\n  📧 ${m.email || 'N/A'} | 📱 ${m.phone || 'N/A'}\n  💼 ${m.position || ''} — ${m.department_name || ''}`).join('\n');
      return { text: `🔍 Kết quả tìm kiếm:\n${list}`, suggestions: ['Đồng nghiệp cùng phòng', 'Quét mã QR'] };
    } catch(e) { return this._error(); }
  }

  // ── LỊCH HỌP ──
  async handleMeetings(userId) {
    try {
      const emp = await this.db.query('SELECT department_id FROM employees WHERE id=$1', [userId]);
      const deptId = emp.rows[0]?.department_id;
      const r = await this.db.query(
        `SELECT title, date, time, link FROM meetings WHERE date >= CURRENT_DATE ORDER BY date, time LIMIT 5`
      );
      if (!r.rows.length) return {
        text: '📅 Hiện tại không có lịch họp nào sắp tới.',
        suggestions: ['Hôm nay chấm công chưa?', 'Xem thống kê', 'Chat Admin']
      };
      const list = r.rows.map(m => {
        const d = new Date(m.date).toLocaleDateString('vi-VN');
        return `• ${m.title}\n  📅 ${d} lúc ${m.time || 'N/A'}${m.link ? '\n  🔗 ' + m.link : ''}`;
      }).join('\n');
      return { text: `📅 Lịch họp sắp tới:\n${list}`, suggestions: ['Hôm nay chấm công chưa?', 'Xem thống kê'] };
    } catch(e) { return this._error(); }
  }

  // ── THÔNG TIN CÁ NHÂN ──
  async handleMyProfile(userId) {
    try {
      const r = await this.db.query('SELECT name, employee_code, email, phone, position, department_name FROM employees WHERE id=$1', [userId]);
      if (!r.rows.length) return { text: 'Không tìm thấy thông tin.', suggestions: ['Chat Admin'] };
      const u = r.rows[0];
      return {
        text: `👤 Thông tin của bạn:\n• Họ tên: ${u.name}\n• Mã NV: ${u.employee_code}\n• Email: ${u.email}\n• SĐT: ${u.phone || 'Chưa cập nhật'}\n• Chức vụ: ${u.position || 'N/A'}\n• Phòng ban: ${u.department_name || 'N/A'}`,
        suggestions: ['Đồng nghiệp cùng phòng', 'Xem thống kê', 'Hôm nay chấm công chưa?']
      };
    } catch(e) { return this._error(); }
  }

  // ── CHÍNH SÁCH ──
  async handlePolicyOvertime() {
    return {
      text: '⏱️ Chính sách tăng ca:\n• Ngày thường: x1.5 lương/giờ\n• Cuối tuần: x2.0 lương/giờ\n• Ngày lễ: x3.0 lương/giờ\n• Tối đa: 40 giờ OT/tháng\n\nĐể đăng ký → vào tab Đơn Từ > Tăng ca.',
      suggestions: ['Cách đăng ký tăng ca', 'Xem thống kê', 'Chat Admin']
    };
  }

  async handlePolicyWork() {
    try {
      const r = await this.db.query('SELECT work_start_time, work_end_time, break_start, break_end FROM company_config LIMIT 1');
      const c = r.rows[0];
      if (!c) return { text: 'Giờ làm việc: 08:00 - 17:30 (Thứ 2 đến Thứ 6)', suggestions: ['Hôm nay chấm công chưa?'] };
      return {
        text: `🕐 Giờ làm việc:\n• Vào: ${c.work_start_time || '08:00'}\n• Ra: ${c.work_end_time || '17:30'}\n• Nghỉ trưa: ${c.break_start || '12:00'} - ${c.break_end || '13:00'}\n• Từ Thứ 2 đến Thứ 6`,
        suggestions: ['Hôm nay chấm công chưa?', 'Đi trễ mấy lần?', 'Xem thống kê']
      };
    } catch(e) { return this._error(); }
  }

  // ── CHÀO HỎI ──
  async handleGreeting(userId) {
    try {
      const u = await this.db.query('SELECT name FROM employees WHERE id=$1', [userId]);
      const name = u.rows[0]?.name || 'bạn';
      const hour = new Date().getHours();
      const greet = hour < 12 ? 'Chào buổi sáng' : hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';
      return {
        text: `${greet}, ${name}! 👋\nTôi là trợ lý ảo WorkMate. Tôi có thể giúp bạn:\n• ⏰ Kiểm tra chấm công\n• 📋 Xem đơn từ & phê duyệt\n• 📊 Thống kê giờ làm\n• 📅 Lịch họp sắp tới\n• 👥 Tìm đồng nghiệp\n\nHãy hỏi tôi bất cứ điều gì!`,
        suggestions: ['Hôm nay chấm công chưa?', 'Xem đơn từ của tôi', 'Còn mấy ngày phép?', 'Lịch họp hôm nay', 'Thông tin của tôi']
      };
    } catch(e) {
      return { text: 'Xin chào! Tôi có thể giúp gì cho bạn?', suggestions: ['Hôm nay chấm công chưa?', 'Xem thống kê'] };
    }
  }

  async handleThanks() {
    return {
      text: '😊 Không có gì! Nếu cần thêm gì cứ hỏi tôi nhé.',
      suggestions: ['Hôm nay chấm công chưa?', 'Xem thống kê', 'Lịch họp']
    };
  }

  async handleConnectAdmin() {
    return {
      text: '🎧 Bạn hãy chuyển sang tab ADMIN để nhắn tin trực tiếp với quản trị viên nhé.',
      suggestions: [], action: 'open_admin_chat'
    };
  }

  // ── HƯỚNG DẪN TÍNH NĂNG ──
  async handleHowToCheckin() {
    return {
      text: '📸 Cách chấm công bằng Face ID:\n1️⃣ Vào trang chủ, nhấn "Chấm công"\n2️⃣ Đưa khuôn mặt vào camera\n3️⃣ Hệ thống sẽ tự động nhận diện\n4️⃣ Khi khớp → chấm công thành công!\n\n💡 Lần đầu cần đăng ký khuôn mặt 5 góc trong phần Cài đặt.',
      suggestions: ['Hôm nay chấm công chưa?', 'Giờ làm việc', 'Chat Admin']
    };
  }

  async handleHowToQR() {
    return {
      text: '📱 Tính năng Quét mã QR:\n1️⃣ Vào Hồ sơ > Mã QR để xem mã QR cá nhân\n2️⃣ Nhấn "Quét mã" để mở camera\n3️⃣ Quét mã QR đồng nghiệp → xem thông tin\n4️⃣ Có thể nhắn tin trực tiếp từ kết quả quét',
      suggestions: ['Tìm đồng nghiệp', 'Đồng nghiệp cùng phòng', 'Thông tin của tôi']
    };
  }

  _error() {
    return { text: 'Xin lỗi, có lỗi khi truy vấn dữ liệu. Vui lòng thử lại sau.', suggestions: ['Thử lại', 'Chat Admin'], source: 'system' };
  }
}

module.exports = HybridChatbot;
