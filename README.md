# 🕐 WorkMate — Ứng dụng Chấm Công Thông Minh

> **"Nâng tầm hiệu suất công việc"**  
> Kiến tạo không gian làm việc số hiện đại và tinh gọn.

---

## 📋 Tổng Quan Dự Án

**WorkMate** là ứng dụng quản lý chấm công và nhân sự dành cho doanh nghiệp, được xây dựng trên nền tảng Flutter với backend Firebase. Hệ thống hỗ trợ đa vai trò (User / HR / Admin / Super Admin), tích hợp GPS, WiFi, Face ID, QR Code và nhiều tính năng quản lý nhân sự hiện đại.

---

## 🎨 Thông Tin Thiết Kế

| Thuộc tính | Giá trị |
|---|---|
| Tên ứng dụng | **WorkMate** |
| Màu chủ đạo | `#4A9FD5` (Xanh dương nhạt) |
| Ngôn ngữ hỗ trợ | Tiếng Việt / Tiếng Anh |
| Platform | iOS & Android |

---

## 🛠️ Công Nghệ Sử Dụng

### Core Stack

| Thành phần | Công nghệ |
|---|---|
| **Ngôn ngữ** | Dart / Flutter |
| **Kiến trúc** | MVVM (Model - View - ViewModel) |
| **Database** | NoSQL |
| **Authentication** | Firebase Auth |
| **Database chính** | Cloud Firestore |
| **Realtime** | Firebase Realtime Database |
| **Backend logic** | Firebase Cloud Functions |
| **Push Notification** | Firebase Cloud Messaging (FCM) |
| **Storage** | Firebase Storage |

### Thư Viện & Package Flutter Đề Xuất

| Package | Mục đích |
|---|---|
| `provider` / `riverpod` | State management cho MVVM |
| `firebase_core` | Kết nối Firebase |
| `firebase_auth` | Xác thực người dùng |
| `cloud_firestore` | Truy vấn dữ liệu NoSQL |
| `firebase_database` | Chat realtime |
| `firebase_messaging` | Push notification |
| `firebase_storage` | Lưu trữ ảnh hồ sơ |
| `google_sign_in` | Đăng nhập Google |
| `local_auth` | Face ID / Fingerprint |
| `geolocator` | Lấy vị trí GPS |
| `google_maps_flutter` | Hiển thị bản đồ |
| `wifi_info_flutter` | Nhận diện mạng WiFi |
| `qr_flutter` | Tạo mã QR |
| `mobile_scanner` | Quét mã QR |
| `excel` | Xuất file Excel |
| `intl` | Đa ngôn ngữ (i18n) |
| `fl_chart` | Biểu đồ thống kê giờ làm |
| `image_picker` | Chọn ảnh từ thư viện/camera |
| `permission_handler` | Quản lý quyền truy cập |
| `dio` / `http` | Gọi API ngoài (ngân hàng, Maps) |
| `shared_preferences` | Lưu cài đặt cục bộ |
| `url_launcher` | Mở app ngân hàng |

---

## 📱 Chức Năng Hệ Thống

### 🔐 Xác Thực & Tài Khoản

- Đăng nhập bằng **Google Account** (Firebase Auth)
- Đăng nhập bằng **Số điện thoại** (OTP Firebase)
- Đăng nhập bằng **Mã nhân viên + Mật khẩu**
- Đăng ký tài khoản mới
- Quên mật khẩu / Đổi mật khẩu
- Đăng xuất
- **Mã nhân viên riêng biệt** cho mỗi tài khoản (tự sinh hoặc do Admin cấp)
- **Mã QR cá nhân** cho mỗi tài khoản

---

### 🏠 Màn Hình Chính (Employee)

#### Chấm Công
- Chấm công **Check In / Check Out** bằng:
  - **Face ID** (nhận diện khuôn mặt)
  - **Vị trí GPS** (trong phạm vi công ty)
  - **WiFi công ty** (chỉ chấm công khi kết nối đúng WiFi)
- Hiển thị giờ/ngày/tháng/năm realtime
- Giờ vào – giờ ra hiển thị trực tiếp trên giao diện
- Kiểm tra khoảng cách tới địa chỉ công ty bằng **Google Maps Distance API**
- Yêu cầu quyền truy cập: Camera, Vị trí, Hình ảnh, WiFi

#### Lịch Làm Việc
- Xem lịch ca làm việc theo tháng (dạng Calendar)
- Chi tiết ca: ngày, giờ vào, giờ ra, loại ca
- Màu sắc phân biệt: Đúng giờ / Trễ / Vắng / Nghỉ lễ

#### Thống Kê
- Tổng số giờ làm trong tuần / tháng
- Biểu đồ làm việc 7 ngày gần nhất
- Số ngày đi muộn / Số ngày nghỉ phép còn lại
- Hiển thị lương tháng hiện tại (theo công thức công ty)

#### Thông Báo
- Nhận push notification từ Admin
- Thông báo duyệt/từ chối yêu cầu nghỉ phép, bổ sung công, OT
- Cập nhật hệ thống & phiên bản mới

---

### 📋 Các Tính Năng Nhân Viên

#### Xin Nghỉ Phép
- Tạo đơn xin nghỉ phép: loại nghỉ, ngày bắt đầu/kết thúc, lý do, bằng chứng (ảnh)
- Theo dõi trạng thái đơn: Chờ duyệt / Đã duyệt / Từ chối
- Lịch sử nghỉ phép

#### Đăng Ký OT (Làm Thêm Giờ)
- Tạo yêu cầu OT: ngày, số giờ dự kiến, nội dung công việc
- Gửi lên HR/Admin phê duyệt
- Lịch sử đăng ký OT & trạng thái

#### Yêu Cầu Bổ Sung Công
- Gửi yêu cầu khi quên chấm công (có lý do, bằng chứng)
- Admin xác nhận và bổ sung thủ công

#### Lịch Họp
- Xem danh sách cuộc họp hôm nay / sắp tới
- Chi tiết: tên cuộc họp, thời gian, địa điểm / link online
- Nhắc nhở trước cuộc họp

#### Hồ Sơ Cá Nhân
- Xem & chỉnh sửa thông tin cá nhân (tên, avatar, email, SĐT)
- Hiển thị mã nhân viên
- Thêm / sửa / xóa tài khoản ngân hàng
- Xem mã QR cá nhân
- Đổi mật khẩu
- Chuyển đổi ngôn ngữ: Tiếng Việt / Tiếng Anh
- Thâm niên công tác

#### Chat Realtime
- Nhắn tin 1-1 hoặc nhóm (dùng Firebase Realtime Database)
- Xem trạng thái online/offline
- Gửi ảnh, file đính kèm

---

### 🛡️ Màn Hình Admin / HR

#### Quản Lý Nhân Viên
- Thêm / Sửa / Xóa hồ sơ nhân viên
- Phân quyền: **User / HR / Admin / Super Admin**
- Tạo mã nhân viên, mã QR cho từng người
- Tạo mã / link / ID để nhân viên tham gia đúng công ty

#### Quản Lý Chấm Công
- Xem trạng thái chấm công toàn bộ nhân viên theo ngày
- Bổ sung công cho nhân viên quên chấm
- Xác nhận yêu cầu bổ sung công từ nhân viên
- Quản lý nhân viên đi trễ

#### Quản Lý Ca Làm Việc
- Tạo / chỉnh sửa ca làm việc (tên ca, giờ vào, giờ ra)
- Phân ca cho nhân viên
- Chỉnh sửa ngày lễ (hệ số x2 / x3)

#### Quản Lý Nghỉ Phép & OT
- Duyệt / Từ chối đơn xin nghỉ phép
- Duyệt / Từ chối yêu cầu OT

#### Thông Báo & Phát Sóng
- Gửi push notification đến toàn bộ nhân viên hoặc theo nhóm
- Tạo thông báo cập nhật hệ thống

#### Xuất Dữ Liệu
- Xuất file **Excel (.xlsx)** số ngày công theo tháng
- Chuyển sang app ngân hàng để trả lương (Deep Link)

#### Hồ Sơ Công Ty
- Tạo và cập nhật thông tin công ty (tên, địa chỉ, tọa độ GPS, SSID WiFi)
- Quản lý phiên bản ứng dụng
- Lịch sử cập nhật hệ thống

---

## 💡 Chức Năng Gợi Ý Bổ Sung

Dưới đây là các chức năng nên cân nhắc thêm vào để hoàn thiện hệ thống:

### Cho Nhân Viên
| STT | Chức năng | Mô tả |
|---|---|---|
| 1 | **Bảng lương chi tiết** | Xem chi tiết lương: lương cơ bản, OT, phụ cấp, thuế, thực nhận |
| 2 | **Slip lương PDF** | Tải phiếu lương dạng PDF từng tháng |
| 3 | **Đánh giá hiệu suất** | Xem KPI, mục tiêu tháng/quý do HR cập nhật |
| 4 | **Widget chấm công** | Shortcut trên màn hình chính điện thoại để check in nhanh |
| 5 | **Offline mode** | Cache dữ liệu để xem lịch, thông tin khi mất mạng |
| 6 | **Dark Mode** | Giao diện tối |
| 7 | **Biometrics đa dạng** | Hỗ trợ cả Face ID và Fingerprint |

### Cho Admin / HR
| STT | Chức năng | Mô tả |
|---|---|---|
| 8 | **Dashboard tổng quan** | Biểu đồ số nhân viên đi làm, trễ, vắng theo ngày/tuần/tháng |
| 9 | **Báo cáo PDF** | Xuất báo cáo chấm công, nghỉ phép dạng PDF |
| 10 | **Quản lý phòng ban** | Tạo phòng ban, gán nhân viên vào phòng ban |
| 11 | **Tính lương tự động** | Cấu hình công thức lương, tự tính dựa trên số công thực tế |
| 12 | **Audit log** | Nhật ký hành động của Admin (ai sửa gì, lúc nào) |
| 13 | **Quản lý hợp đồng** | Upload & lưu trữ hợp đồng lao động |
| 14 | **Import nhân viên hàng loạt** | Upload file Excel để tạo nhiều tài khoản cùng lúc |
| 15 | **Webhook / API tích hợp** | Tích hợp với HRM hoặc phần mềm kế toán bên ngoài |

---

## 🏗️ Kiến Trúc MVVM

```
lib/
├── core/
│   ├── constants/          # Màu sắc, chuỗi, routes
│   ├── utils/              # Helper functions
│   └── services/           # Firebase services, GPS, WiFi
├── data/
│   ├── models/             # User, Attendance, Leave, OT, ...
│   ├── repositories/       # Truy vấn Firestore / Realtime DB
│   └── datasources/        # Remote (Firebase) & Local (SharedPrefs)
├── presentation/
│   ├── views/              # Màn hình UI (Screens & Widgets)
│   └── viewmodels/         # ChangeNotifier / StateNotifier
├── l10n/                   # File đa ngôn ngữ (vi.arb, en.arb)
└── main.dart
```

---

## 🗄️ Cấu Trúc Firestore (NoSQL)

```
/companies/{companyId}
    name, address, lat, lng, wifiSSID, ...

/users/{userId}
    employeeCode, name, role, departmentId, companyId, bankAccounts[], ...

/attendances/{attendanceId}
    userId, checkIn, checkOut, method (FaceID/GPS/WiFi), date, status, ...

/leaves/{leaveId}
    userId, type, fromDate, toDate, reason, status, attachments[], ...

/overtimes/{otId}
    userId, date, hours, workContent, status, ...

/shifts/{shiftId}
    name, startTime, endTime, companyId, ...

/notifications/{notifId}
    title, body, targetRole, createdAt, ...

/chats/{chatId}/messages/{messageId}
    senderId, text, timestamp, ...
```

---

## 🔐 Phân Quyền Hệ Thống

| Role | Quyền hạn |
|---|---|
| **User** | Chấm công, xem lịch, xin nghỉ, đăng ký OT, chat, xem lương |
| **HR** | Tất cả quyền User + duyệt đơn nghỉ/OT, quản lý chấm công, xem báo cáo |
| **Admin** | Tất cả quyền HR + quản lý nhân viên, ca làm, thông báo, xuất Excel |
| **Super Admin** | Tất cả quyền Admin + cấu hình hệ thống, phân quyền, lịch sử hệ thống |

---

## 🔒 Bảo Mật

- Firebase Security Rules cho Firestore & Storage
- Xác thực token JWT tự động qua Firebase Auth
- Mã hóa thông tin nhạy cảm (tài khoản ngân hàng)
- Xác thực OTP khi đổi thông tin quan trọng
- Face ID / Fingerprint cho mỗi phiên chấm công

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Dự Án

### Yêu Cầu
- Flutter SDK >= 3.x
- Dart >= 3.x
- Android Studio / Xcode
- Tài khoản Firebase (project riêng)

### Các Bước

```bash
# 1. Clone repo
git clone https://github.com/your-org/workmate.git
cd workmate

# 2. Cài đặt dependencies
flutter pub get

# 3. Cấu hình Firebase
# - Tải google-services.json (Android) vào android/app/
# - Tải GoogleService-Info.plist (iOS) vào ios/Runner/
# - Chạy: flutterfire configure

# 4. Chạy ứng dụng
flutter run
```

---

## 📸 Giao Diện Ứng Dụng

| Màn hình | Mô tả |
|---|---|
| Splash / Onboarding | Giới thiệu ứng dụng |
| Đăng nhập | Mã nhân viên, Google, SĐT |
| Trang chủ | Check In/Out, Workspace nhanh |
| Thông báo | Tin tức, cảnh báo, thông báo hệ thống |
| Thống kê | Biểu đồ giờ làm, lịch sử chấm công |
| Lịch làm việc | Calendar ca làm |
| Xin nghỉ phép | Form tạo đơn nghỉ |
| Đăng ký OT | Form làm thêm giờ |
| Lịch họp | Danh sách & chi tiết cuộc họp |
| Hồ sơ & Cài đặt | Thông tin cá nhân, ngân hàng, ngôn ngữ |
| Chat | Nhắn tin realtime |
| Admin Dashboard | Quản lý toàn hệ thống |

---

## 📄 Giấy Phép

Dự án được phát triển cho mục đích học thuật và nội bộ doanh nghiệp.

---

> **WorkMate Ecosystem © 2025** — Phát triển bởi nhóm sinh viên / đội ngũ kỹ thuật.
