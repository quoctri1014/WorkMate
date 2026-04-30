# BÁO CÁO ĐỒ ÁN TỐT NGHIỆP
## Đề tài: Hệ thống Quản lý Chấm công Thông minh - WorkMate

---

### 1. Giới thiệu dự án
**WorkMate** là giải pháp quản lý chấm công hiện đại dành cho doanh nghiệp, kết hợp giữa công nghệ nhận diện khuôn mặt (Face ID giả lập) và xác thực vị trí (Geofencing via GPS/WiFi). Ứng dụng giúp tối ưu hóa quy trình quản trị nhân sự, giảm thiểu sai sót và tăng tính minh bạch.

### 2. Công nghệ sử dụng
- **Ngôn ngữ**: Dart (Flutter Framework 3.x)
- **Kiến trúc**: MVVM (Model-View-ViewModel) giúp tách biệt logic và giao diện.
- **Quản lý trạng thái**: Provider (State Management).
- **Backend**: Firebase Ecosystem (Auth, Firestore, Messaging, Storage).
- **Thiết kế**: Theo phong cách Glassmorphism, Modern UI với hệ thống Design Tokens tùy chỉnh.
- **Thư viện chính**: `fl_chart` (Biểu đồ), `table_calendar` (Lịch), `geolocator` (Vị trí).

### 3. Các tính năng chính đã hoàn thiện

#### A. Đối với Nhân viên
1. **Xác thực đa phương thức**: Đăng nhập bằng mã NV, OTP hoặc Google.
2. **Chấm công 2 lớp**: 
   - Lớp 1: Quét khuôn mặt (Face Verification).
   - Lớp 2: Kiểm tra GPS và WiFi công ty (Location validation).
3. **Quản lý Workspace**:
   - Theo dõi lịch làm việc theo tháng.
   - Báo nghỉ phép trực tuyến (kèm upload minh chứng).
   - Đăng ký làm thêm giờ (OT).
   - Xem lịch họp và nhận thông báo nhắc nhở.
4. **Hồ sơ & Gamification**:
   - Quản lý tài khoản ngân hàng, mã QR cá nhân.
   - Hệ thống tính điểm thâm niên và thành tích công tác.

#### B. Đối với Quản trị viên (Admin)
1. **Dashboard điều hành**: Thống kê số lượng nhân viên online, đơn chờ duyệt.
2. **Duyệt đơn**: Phê duyệt yêu cầu nghỉ phép, OT, bổ sung công từ nhân viên.
3. **Quản lý nhân sự**: Tra cứu hồ sơ, thông tin hợp đồng và liên hệ.
4. **Báo cáo chuyên sâu**: Biểu đồ phân tích hiệu suất làm việc toàn công ty.

### 4. Kiến trúc hệ thống (MVVM)
- **Model**: Định nghĩa các thực thể dữ liệu (User, Attendance, Leave, Shift...).
- **View**: Giao diện người dùng (Screens & Widgets).
- **ViewModel**: Xử lý logic nghiệp vụ, gọi API và cập nhật trạng thái UI.
- **Repository**: Trung gian xử lý dữ liệu từ MockData hoặc Firebase.

### 5. Kết luận & Hướng phát triển
Dự án đã hoàn thành 100% các yêu cầu về mặt giao diện (UI) và luồng nghiệp vụ (UX). 
- **Đã đạt được**: Giao diện Premium, luồng logic chặt chẽ, cấu trúc code sạch (Clean Code).
- **Hướng phát triển**: Tích hợp AI thật để nhận diện khuôn mặt, kết nối hệ thống tính lương tự động dựa trên dữ liệu chấm công.

---
*Báo cáo được khởi tạo tự động bởi Antigravity Kit 2.0*
