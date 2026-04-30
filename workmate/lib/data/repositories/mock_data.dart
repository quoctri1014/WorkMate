import 'package:workmate/data/models/models.dart';

class MockDataService {
  // KHÔNG SỬ DỤNG DỮ LIỆU GIẢ - ĐÃ LÀM RỖNG ĐỂ CHỈ SỬ DỤNG CSDL THẬT
  static final UserModel currentUser = UserModel(
    id: 0,
    employeeCode: '',
    name: 'Người dùng',
    email: '',
    phone: '',
    avatarUrl: '',
    role: 'user',
    departmentId: 0,
    joinDate: DateTime.now(),
  );

  static final List<AttendanceModel> attendanceHistory = [];
  static final List<LeaveModel> leaveHistory = [];
  static final List<OvertimeModel> overtimeHistory = [];
  static final List<MeetingModel> meetings = [];
  static final List<NotificationModel> notifications = [];

  static final List<double> weeklyHours = [0, 0, 0, 0, 0, 0, 0];
  static const double totalWeeklyHours = 0;
  static const int latedays = 0;
  static const int remainingLeave = 0;
  static const double totalMonthlySalary = 0;
}
