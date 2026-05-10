# Hướng Dẫn Cài Đặt và Chạy Dự Án WorkMate

Dự án WorkMate bao gồm 3 phần chính:
1.  **Backend (Node.js + PostgreSQL)**: Xử lý logic, API, Database.
2.  **Web Admin (React + Vite)**: Giao diện quản lý dành cho Admin.
3.  **Mobile App (Flutter)**: Ứng dụng dành cho nhân viên.

Dưới đây là hướng dẫn chi tiết để chạy từng phần trên môi trường local.

---

## 1. Yêu cầu hệ thống (Prerequisites)

Trước khi bắt đầu, đảm bảo máy tính của bạn đã cài đặt các phần mềm sau:
-   **Node.js** (Khuyến nghị bản LTS, >= v18)
-   **PostgreSQL** (Khuyến nghị bản >= v15)
-   **Flutter SDK** (Khuyến nghị bản >= 3.22.x)
-   **Android Studio** (Để chạy máy ảo Android) hoặc **Xcode** (nếu dùng máy Mac để chạy iOS)
-   **Git**

---

## 2. Thiết lập Database (PostgreSQL)

1.  Mở pgAdmin hoặc công cụ quản lý PostgreSQL.
2.  Tạo một database mới có tên là `workmate`.
3.  (Tùy chọn) Chạy script `init.sql` nằm trong thư mục `workmate_backend` để tạo các bảng cơ sở dữ liệu ban đầu. Tuy nhiên, Backend đã có tính năng tự động tạo bảng (migration) khi chạy lần đầu.

---

## 3. Khởi chạy Backend (Node.js)

1.  Mở terminal, di chuyển vào thư mục backend:
    ```bash
    cd d:\TTTN\workmate_backend
    ```
2.  Cài đặt các gói thư viện (dependencies):
    ```bash
    npm install
    ```
3.  Cấu hình biến môi trường:
    -   Tạo (hoặc mở) file `.env` trong thư mục `workmate_backend`.
    -   Đảm bảo các cấu hình Database và API Key là chính xác. Mẫu `.env`:
        ```env
        DB_USER=postgres
        DB_HOST=localhost
        DB_NAME=workmate
        DB_PASSWORD=mat_khau_postgres_cua_ban
        DB_PORT=5432
        
        # Google Gemini AI Key
        GEMINI_API_KEY=your_gemini_api_key_here
        
        # Email cấu hình để gửi OTP
        EMAIL_USER=your_email@gmail.com
        EMAIL_PASS=your_app_password
        
        JWT_SECRET=your_jwt_secret_key
        ```
    -   *Lưu ý: Thay thế các thông tin bằng cấu hình thực tế của máy bạn.*
4.  Chạy server:
    ```bash
    node index.js
    ```
    *Nếu thấy thông báo `✅ Database đã được đồng bộ hóa thành công!` và server lắng nghe ở cổng `5000` nghĩa là backend đã sẵn sàng.*

---

## 4. Khởi chạy Web Admin (React)

1.  Mở một tab terminal mới, di chuyển vào thư mục Web Admin:
    ```bash
    cd d:\TTTN\workmate_web
    ```
    *(Thay đổi tên thư mục `workmate_web` nếu dự án React của bạn có tên khác).*
2.  Cài đặt các gói thư viện:
    ```bash
    npm install
    ```
3.  Khởi chạy chế độ phát triển:
    ```bash
    npm run dev
    ```
4.  Mở trình duyệt và truy cập vào đường dẫn được hiển thị trên terminal (thường là `http://localhost:5173`).

---

## 5. Khởi chạy Mobile App (Flutter)

1.  Mở một tab terminal mới, di chuyển vào thư mục Mobile App:
    ```bash
    cd d:\TTTN\workmate
    ```
2.  Cài đặt các gói thư viện:
    ```bash
    flutter pub get
    ```
3.  **Quan trọng: Cấu hình IP cho ứng dụng gọi API**
    -   Mở file `lib/data/repositories/api_service.dart`.
    -   Tìm biến `baseHost`.
    -   Nếu bạn chạy trên **Android Emulator**, IP mặc định `http://10.0.2.2:5000` thường sẽ hoạt động.
    -   Nếu bạn chạy trên **Thiết bị thật** hoặc **iOS Simulator**, bạn cần đổi IP thành IP LAN của máy tính đang chạy Backend (Ví dụ: `http://192.168.1.x:5000`).
        *Để lấy IP LAN: Mở terminal gõ `ipconfig` (Windows) hoặc `ifconfig` (Mac) và tìm địa chỉ IPv4.*

4.  Khởi chạy ứng dụng:
    -   Đảm bảo bạn đã mở máy ảo Android/iOS hoặc kết nối thiết bị thật.
    -   Chạy lệnh:
        ```bash
        flutter run
        ```

---

## 6. Tài khoản Đăng nhập Mặc định

Nếu đây là lần chạy đầu tiên và bạn chưa có dữ liệu, bạn có thể tạo một tài khoản thủ công trong CSDL PostgreSQL, hoặc sử dụng tính năng đăng ký nếu ứng dụng có hỗ trợ.

*Để tạo nhanh một Admin:*
```sql
INSERT INTO employees (employee_code, name, email, password_hash, role)
VALUES ('ADMIN01', 'Quản trị viên', 'admin@workmate.com', '$2b$10$YourHashedPasswordHere', 'admin');
```
*(Cần dùng bcrypt để tạo chuỗi `password_hash` hợp lệ trước khi insert).*

---
🎉 **Chúc bạn chạy dự án thành công!** Nếu gặp bất kỳ lỗi nào, hãy kiểm tra lại thông báo lỗi trong terminal.
