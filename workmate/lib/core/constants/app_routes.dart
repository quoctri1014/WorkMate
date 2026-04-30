class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Main
  static const String main = '/main';

  // Home
  static const String home = '/home';

  // Attendance
  static const String checkIn = '/check-in';
  static const String checkInPermission = '/check-in/permission';
  static const String checkInFace = '/check-in/face';
  static const String checkInLocation = '/check-in/location';
  static const String checkInSuccess = '/check-in/success';

  // Schedule
  static const String schedule = '/schedule';

  // Leave
  static const String leaveRequest = '/leave/request';
  static const String leaveHistory = '/leave/history';
  static const String leaveDetail = '/leave/detail';

  // Overtime
  static const String otRequest = '/ot/request';
  static const String otHistory = '/ot/history';
  static const String otDetail = '/ot/detail';

  // Meeting
  static const String meeting = '/meeting';
  static const String meetingDetail = '/meeting/detail';

  // Statistics
  static const String statistics = '/statistics';

  // Notification
  static const String notification = '/notification';

  // Profile
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String bankAccount = '/profile/bank';
  static const String changePassword = '/profile/change-password';
  static const String qrCode = '/profile/qr';
  static const String language = '/profile/language';
  static const String seniority = '/profile/seniority';

  // Supplement
  static const String supplementRequest = '/supplement/request';

  // Chat
  static const String chat = '/chat';
  static const String chatDetail = '/chat/detail';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminEmployees = '/admin/employees';
  static const String adminAttendance = '/admin/attendance';
  static const String adminLeaveApproval = '/admin/leave-approval';
  static const String adminOTApproval = '/admin/ot-approval';
  static const String adminShifts = '/admin/shifts';
  static const String adminNotification = '/admin/notification';
  static const String announcementDetail = '/announcement/detail';
}
