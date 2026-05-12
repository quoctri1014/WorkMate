# 🚀 WorkMate - Hệ Thống Quản Lý Chấm Công Thông Minh

**WorkMate** là giải pháp quản lý nhân sự và chấm công hiện đại, kết hợp sức mạnh của trí tuệ nhân tạo on-device (Edge AI) và xác thực đa lớp (Multi-layer Validation). Dự án được phát triển nhằm giải quyết triệt để vấn đề gian lận chấm công và tối ưu hóa quy trình quản trị doanh nghiệp.

---

## ✨ Tính Năng Cốt Lõi

### 1. 🎭 Chấm Công FaceID & Liveness (AI On-device)
*   **Nhận diện đa hướng:** Đăng ký và nhận diện với **5 góc mặt** (chính diện, trái, phải, trên, dưới) để đạt độ chính xác tối ưu.
*   **Chống giả mạo (Liveness Detection):** Tích hợp thuật toán phát hiện nháy mắt (Blink Detection) để phân biệt người thật và ảnh chụp/video.
*   **Xử lý cục bộ:** Toàn bộ quá trình trích xuất vector khuôn mặt (192D) diễn ra ngay trên thiết bị, đảm bảo quyền riêng tư và tốc độ xử lý < 400ms.

### 2. 📍 Xác Thực Đa Lớp (Secure Zone)
*   **GPS Geofencing:** Chỉ cho phép chấm công trong bán kính cho phép (văn phòng/công trình) sử dụng công thức Haversine chính xác.
*   **WiFi Fingerprinting:** Ràng buộc kết nối đúng WiFi nội bộ của công ty thông qua SSID/BSSID.

### 3. 🤖 Trợ Lý Ảo WorkMate (Context-Aware Assistant)
*   **Hybrid Rule-based Chatbot:** Tự động trả lời các câu hỏi về ngày phép, giờ làm, nội quy công ty.
*   **Truy vấn realtime:** Bot kết nối trực tiếp với PostgreSQL để đưa ra con số chính xác 100% cho từng nhân viên.

### 4. 📊 Dashboard Quản Trị & Realtime
*   **Realtime Communication:** Tích hợp Socket.IO giúp Admin nhận thông báo chấm công và phê duyệt đơn từ ngay lập tức.
*   **Xuất báo cáo:** Hỗ trợ xuất dữ liệu chấm công tháng ra file Excel (.xlsx) chuyên nghiệp.
*   **Dark Mode:** Giao diện hỗ trợ chế độ tối hoàn chỉnh trên cả App và Web.

---

## 🛠 Công Nghệ Sử Dụng

| Thành phần | Công nghệ |
| :--- | :--- |
| **Mobile App** | Flutter (Provider, ML Kit, TFLite, Socket.IO Client) |
| **Web Admin** | React (Vite, TailwindCSS, Socket.IO Client) |
| **Backend** | Node.js (Express, Socket.IO Server, BCrypt, ExcelJS) |
| **Database** | PostgreSQL (JSONB, Vector Storage) |
| **Cloud** | Firebase (Cloud Messaging, Storage) |
| **CI/CD** | Codemagic (Tự động Build iOS/Android) |

---

## 📂 Cấu Trúc Thư Mục

*   `/workmate`: Mã nguồn ứng dụng di động Flutter.
*   `/workmate_admin`: Mã nguồn Dashboard quản trị React.
*   `/workmate_backend`: Mã nguồn API server Node.js.
*   `Bao_Cao.pdf`: Tài liệu báo cáo chi tiết đồ án.

---

## 🚀 Hướng Dẫn Cài Đặt

### 1. Cấu hình Backend
1. Di chuyển vào thư mục: `cd workmate_backend`
2. Cài đặt thư viện: `npm install`
3. Tạo file `.env` từ mẫu:
   ```env
   DB_USER=postgres
   DB_HOST=localhost
   DB_NAME=workmate_db
   DB_PASSWORD=1
   DB_PORT=5432
   JWT_SECRET=your_secret_key
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASS=your_app_password
   ```
4. Chạy server: `node index.js`

### 2. Cấu hình Web Admin
1. Di chuyển vào thư mục: `cd workmate_admin`
2. Cài đặt và chạy: `npm install && npm run dev`

### 3. Cấu hình Mobile App
1. Di chuyển vào thư mục: `cd workmate`
2. Lấy thư viện: `flutter pub get`
3. Cấu hình IP server trong `lib/data/repositories/api_service.dart`.
4. Chạy ứng dụng: `flutter run`

---

## 🛡️ Bảo Mật & Privacy
*   Không lưu trữ ảnh gốc của nhân viên (chỉ lưu vector số hóa).
*   Mật khẩu được băm (hashing) bằng thuật toán BCrypt.
*   Cơ chế Parameterized Queries chống tấn công SQL Injection.

---
© 2026 WorkMate Ecosystem. Đồ án tốt nghiệp chuyên ngành CNTT.
