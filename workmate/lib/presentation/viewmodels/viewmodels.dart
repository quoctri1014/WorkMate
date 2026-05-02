import 'package:flutter/material.dart';
import 'package:workmate/data/models/models.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workmate/data/repositories/api_service.dart';
// import 'package:workmate/data/repositories/firebase_service.dart';
import '../../services/notification_service.dart';

class NotificationEvents {
  static final _RefreshBus refreshBus = _RefreshBus();
  static void emitRefresh() => refreshBus.trigger();
}

class _RefreshBus extends ChangeNotifier {
  void trigger() => notifyListeners();
}

class AuthViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  // Không dùng FirebaseService nữa vì đã chuyển sang Node.js/PostgreSQL
  
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('saved_employee_code');
    final savedPassword = prefs.getString('saved_password');
    
    // We don't auto-login anymore, just load data for pre-fill if needed
    // or we can just leave this for the LoginScreen to call getSavedCredentials
  }

  Future<Map<String, String>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'code': prefs.getString('saved_employee_code') ?? '',
      'password': prefs.getString('saved_password') ?? '',
    };
  }

  Future<bool> loginWithEmployeeCode(String code, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _api.login(code, password);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(user.toMap()));
        
        // Lưu thông tin đăng nhập để pre-fill lần sau
        await prefs.setString('saved_employee_code', code);
        await prefs.setString('saved_password', password);
        
        // Cập nhật FCM Token lên Server
        await NotificationService().updateTokenOnServer(user.id);
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw Exception("Đăng nhập thất bại");
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> sendOTP(int employeeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'employee_id': employeeId}),
      );
      _isLoading = false;
      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        _errorMessage = data['error'] ?? data['message'] ?? 'Gửi OTP thất bại';
        notifyListeners();
        throw Exception(_errorMessage);
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> changePasswordWithOTP(int employeeId, String newPassword, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employee_id': employeeId,
          'new_password': newPassword,
          'otp': otp,
        }),
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    // Đã chuyển sang Node.js, nên dùng changePasswordWithOTP
    throw UnimplementedError("Sử dụng changePasswordWithOTP thay thế");
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFaceId(dynamic embedding) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _api.registerFace(_currentUser!.id, embedding);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('last_check_in'); // Xóa luôn trạng thái chấm công cũ
    notifyListeners();
  }
}

class HomeViewModel extends ChangeNotifier {
  UserModel? user;
  bool _isCheckingIn = false;
  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String _currentTime = '';
  CompanyConfigModel? companyConfig;
  
  void setUser(UserModel u) {
    user = u;
    fetchConfig();
    notifyListeners();
  }

  Future<void> fetchConfig() async {
    final config = await ApiService().getCompanyConfig();
    if (config != null) {
      companyConfig = config;
      notifyListeners();
    }
  }

  Future<void> fetchUserProfile() async {
    if (user == null) return;
    try {
      final updatedUser = await ApiService().getUserByCode(user!.employeeCode);
      if (updatedUser != null) {
        // Fetch banks too
        final banks = await ApiService().getEmployeeBanks(updatedUser.id);
        user = UserModel(
          id: updatedUser.id,
          employeeCode: updatedUser.employeeCode,
          name: updatedUser.name,
          email: updatedUser.email,
          phone: updatedUser.phone,
          avatarUrl: updatedUser.avatarUrl,
          role: updatedUser.role,
          departmentId: updatedUser.departmentId,
          departmentName: updatedUser.departmentName,
          position: updatedUser.position,
          joinDate: updatedUser.joinDate,
          birthday: updatedUser.birthday,
          baseSalary: updatedUser.baseSalary,
          bankAccounts: banks,
          seniorityPoints: updatedUser.seniorityPoints,
          technicalScore: updatedUser.technicalScore,
          teamworkScore: updatedUser.teamworkScore,
          creativityScore: updatedUser.creativityScore,
        );
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi fetchUserProfile: $e');
    }
  }

  Future<void> addBank(Map<String, dynamic> data) async {
    if (user == null) return;
    final newBank = await ApiService().addEmployeeBank(user!.id, data);
    if (newBank != null) {
      await fetchUserProfile();
    }
  }

  Future<void> updateBank(int bankId, Map<String, dynamic> data) async {
    final updated = await ApiService().updateEmployeeBank(bankId, data);
    if (updated != null) {
      await fetchUserProfile();
    }
  }

  Future<void> deleteBank(int bankId) async {
    final success = await ApiService().deleteEmployeeBank(bankId);
    if (success) {
      await fetchUserProfile();
    }
  }

  void updateUserAvatar(String url) {
    if (user != null) {
      user = UserModel(
        id: user!.id,
        employeeCode: user!.employeeCode,
        name: user!.name,
        email: user!.email,
        phone: user!.phone,
        departmentId: user!.departmentId,
        departmentName: user!.departmentName,
        position: user!.position,
        joinDate: user!.joinDate,
        birthday: user!.birthday,
        avatarUrl: url,
        seniorityPoints: user!.seniorityPoints,
        technicalScore: user!.technicalScore,
        teamworkScore: user!.teamworkScore,
        creativityScore: user!.creativityScore,
      );
      notifyListeners();
    }
  }

  bool get isCheckingIn => _isCheckingIn;
  bool get isCheckedIn => _isCheckedIn;
  DateTime? get checkInTime => _checkInTime;
  DateTime? get checkOutTime => _checkOutTime;
  String get currentTime => _currentTime;

  void updateTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    _currentTime = '$h:$m:$s';
    notifyListeners();
  }

  Future<void> fetchTodayAttendance() async {
    if (user == null) return;
    try {
      // Đợi 1 chút để DB kịp cập nhật nếu vừa chấm công xong
      await Future.delayed(const Duration(milliseconds: 500));
      
      final attendance = await ApiService().getTodayAttendance(user!.id);
      print('📡 Attendance Data: $attendance');
      
      if (attendance != null) {
        if (attendance['check_in_time'] != null) {
          _checkInTime = DateTime.parse(attendance['check_in_time']);
        }
        if (attendance['check_out_time'] != null) {
          _checkOutTime = DateTime.parse(attendance['check_out_time']);
          _isCheckedIn = false;
        } else {
           _isCheckedIn = attendance['check_in_time'] != null;
        }
      } else {
        _isCheckedIn = false;
        _checkInTime = null;
        _checkOutTime = null;
      }
      notifyListeners();
    } catch (e) {
      print('❌ Lỗi fetchTodayAttendance: $e');
    }
  }

  Future<bool> performCheckIn() async {
    // Không dùng mock nữa, CheckInFaceScreen gọi API rồi gọi fetchTodayAttendance
    return true;
  }

  Future<bool> performCheckOut() async {
    return true;
  }
}

class AttendanceViewModel extends ChangeNotifier {
  List<AttendanceModel> _history = [];
  List<AttendanceModel> get history => _history;
  bool _faceVerified = false;
  bool _locationVerified = false;
  bool _isLoading = false;

  bool get faceVerified => _faceVerified;
  bool get locationVerified => _locationVerified;
  bool get isLoading => _isLoading;
  bool get canCheckIn => _faceVerified && _locationVerified;

  Future<bool> verifyFace() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 3));
    _faceVerified = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> verifyLocation() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _locationVerified = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void reset() {
    _faceVerified = false;
    _locationVerified = false;
    notifyListeners();
  }
}

class LeaveViewModel extends ChangeNotifier {
  List<LeaveModel> _leaves = [];
  bool _isLoading = false;
  double _remainingLeave = 12.0;
  int? _lastEmployeeId;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  LeaveViewModel() {
    NotificationEvents.refreshBus.addListener(_onNotificationRefresh);
  }

  void _onNotificationRefresh() {
    if (_lastEmployeeId != null) {
      fetchLeaves(_lastEmployeeId!);
    }
  }

  @override
  void dispose() {
    NotificationEvents.refreshBus.removeListener(_onNotificationRefresh);
    super.dispose();
  }

  List<LeaveModel> get leaves => _leaves;
  bool get isLoading => _isLoading;
  double get remainingLeave => _remainingLeave;
  double get usedLeave => 12.0 - _remainingLeave;
  double get totalLeave => 12.0;

  Future<bool> submitLeaveRequest({
    required int employeeId,
    required String employeeName,
    required String leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    List<String> attachments = const [],
    bool isHalfDay = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Kiểm tra trùng lịch nghỉ
      final bool isOverlapping = _leaves.any((l) {
        if (l.status == 'rejected') return false;
        
        // Chỉ so sánh ngày (loại bỏ giờ để chính xác)
        final DateTime start1 = DateTime(fromDate.year, fromDate.month, fromDate.day);
        final DateTime end1 = DateTime(toDate.year, toDate.month, toDate.day);
        final DateTime start2 = DateTime(l.fromDate.year, l.fromDate.month, l.fromDate.day);
        final DateTime end2 = DateTime(l.toDate.year, l.toDate.month, l.toDate.day);

        return (start1.isBefore(end2.add(const Duration(days: 1))) && 
                end1.isAfter(start2.subtract(const Duration(days: 1))));
      });

      if (isOverlapping) {
        _errorMessage = 'Ngày này đã được đăng ký nghỉ phép. Bạn không thể tạo thêm đơn mới cho cùng một khoảng thời gian.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final double totalDays = isHalfDay ? 0.5 : (toDate.difference(fromDate).inDays + 1).toDouble();
      final double totalHours = totalDays * 8.0;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/approvals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employee_id': employeeId,
          'employee_name': employeeName,
          'type': leaveType,
          'reason': reason,
          'from_date': fromDate.toIso8601String(),
          'to_date': toDate.toIso8601String(),
          'attachment_urls': attachments,
          'is_half_day': isHalfDay,
          'total_hours': totalHours,
        }),
      );
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 200) {
        await fetchLeaves(employeeId);
        return true;
      } else {
        print('❌ Lỗi Server (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Lỗi kết nối gửi đơn: $e');
      return false;
    }
  }

  Future<void> fetchLeaves(int employeeId) async {
    _lastEmployeeId = employeeId;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/approvals?employee_id=$employeeId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        List<LeaveModel> parsedLeaves = [];
        for (var item in data) {
          try {
            parsedLeaves.add(LeaveModel.fromMap(item));
          } catch (e) {
            print('⚠️ Lỗi parse đơn nghỉ (ID: ${item['id']}): $e');
          }
        }
        _leaves = parsedLeaves;
        
        // Cập nhật số ngày nghỉ còn lại từ API statistics
        print('🔄 Đang cập nhật số ngày nghỉ cho nhân viên $employeeId...');
        final statsResponse = await http.get(Uri.parse('${ApiService.baseUrl}/statistics/$employeeId'));
        if (statsResponse.statusCode == 200) {
          final statsData = json.decode(statsResponse.body);
          _remainingLeave = double.tryParse(statsData['remainingLeave'].toString()) ?? 12.0;
          print('✅ Cập nhật số ngày nghỉ thành công: $_remainingLeave ngày');
        } else {
          print('❌ Lỗi lấy statistics (${statsResponse.statusCode}): ${statsResponse.body}');
        }
      }
    } catch (e) {
      print('❌ Lỗi FetchLeaves: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}

class OvertimeViewModel extends ChangeNotifier {
  List<OvertimeModel> _overtimes = [];
  bool _isLoading = false;
  int? _lastEmployeeId;

  OvertimeViewModel() {
    NotificationEvents.refreshBus.addListener(_onNotificationRefresh);
  }

  void _onNotificationRefresh() {
    if (_lastEmployeeId != null) {
      fetchOvertimes(_lastEmployeeId!);
    }
  }

  @override
  void dispose() {
    NotificationEvents.refreshBus.removeListener(_onNotificationRefresh);
    super.dispose();
  }

  List<OvertimeModel> get overtimes => _overtimes;
  bool get isLoading => _isLoading;

  double get totalOTHours => _overtimes
      .where((o) => o.status == 'approved')
      .fold(0.0, (sum, o) => sum + o.expectedHours);

  Future<bool> submitOTRequest({
    required int employeeId,
    required String employeeName,
    required DateTime date,
    required double hours,
    required String workContent,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/overtimes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'employee_id': employeeId,
          'employee_name': employeeName,
          'date': date.toIso8601String(),
          'hours': hours,
          'reason': workContent,
        }),
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Lỗi gửi đơn OT: $e');
      return false;
    }
  }

  Future<void> fetchOvertimes(int employeeId) async {
    _lastEmployeeId = employeeId;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/approvals?employee_id=$employeeId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _overtimes = data
            .map((json) => OvertimeModel.fromMap(json))
            .where((o) => o.workContent != '' && o.expectedHours > 0) // Basic filter if needed
            .toList();
      }
    } catch (e) {
      print('❌ Lỗi lấy lịch sử OT: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}

class StatisticsViewModel extends ChangeNotifier {
  double _totalHours = 0;
  double _totalOTHours = 0;
  int _lateDays = 0;
  double _remainingLeave = 12.0;
  List<Map<String, double>> _weeklyDataMap = List.generate(7, (_) => {'normal': 0, 'ot': 0, 'deficiency': 0});
  List<AttendanceModel> _attendanceHistory = [];
  bool _isLoading = false;

  StatisticsViewModel() {
    NotificationEvents.refreshBus.addListener(_onNotificationRefresh);
  }

  int? _lastEmployeeId;
  void _onNotificationRefresh() {
    if (_lastEmployeeId != null) {
      fetchStatistics(_lastEmployeeId!);
    }
  }

  @override
  void dispose() {
    NotificationEvents.refreshBus.removeListener(_onNotificationRefresh);
    super.dispose();
  }

  double get totalHours => _totalHours;
  double get totalOTHours => _totalOTHours;
  int get lateDays => _lateDays;
  double get remainingLeave => _remainingLeave;
  List<Map<String, double>> get weeklyDataMap => _weeklyDataMap;
  List<AttendanceModel> get attendanceHistory => _attendanceHistory;
  bool get isLoading => _isLoading;

  Future<void> fetchStatistics(int employeeId, {String period = 'week', DateTime? startDate, DateTime? endDate}) async {
    _lastEmployeeId = employeeId;
    _isLoading = true;
    notifyListeners();
    try {
      String url = '${ApiService.baseUrl}/statistics/$employeeId?period=$period';
      if (startDate != null && endDate != null) {
        url = '${ApiService.baseUrl}/statistics/$employeeId?start_date=${startDate.toIso8601String().split('T')[0]}&end_date=${endDate.toIso8601String().split('T')[0]}';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Statistics Data: $data');
        _totalHours = double.parse(data['totalHours'].toString());
        _totalOTHours = double.parse(data['totalOTHours'].toString());
        _lateDays = int.parse(data['lateDays'].toString());
        _remainingLeave = double.parse(data['remainingLeave'].toString());
        
        final List<dynamic> weekly = data['weeklyData'];
        _weeklyDataMap = weekly.map((d) => {
          'normal': double.parse(d['normal'].toString()),
          'ot': double.parse(d['ot'].toString()),
          'deficiency': double.parse(d['deficiency'].toString()),
        }).toList();

        final List<dynamic> history = data['history'];
        _attendanceHistory = history.map((json) => AttendanceModel.fromMap(json, json['id'].toString())).toList();
      }
    } catch (e) {
      print('❌ Lỗi fetchStatistics: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  // Helper for UI
  double get totalWeeklyHours => _totalHours;
  List<double> get weeklyData => _weeklyDataMap.map((d) => d['normal']! + d['ot']! + d['deficiency']!).toList();
}

class NotificationViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  IO.Socket? _socket;
  int? _currentUserId;
  
  NotificationViewModel() {
    _initSocket();
  }

  List<NotificationModel> get notifications => _notifications;

  Future<void> initForUser(int userId) async {
    _currentUserId = userId;
    _socket?.emit('register', userId);
    await _loadNotifications();
  }

  void clear() {
    _notifications = [];
    _currentUserId = null;
    notifyListeners();
  }

  Future<void> _loadNotifications() async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notifsJson = prefs.getString('notifications_$_currentUserId');
      if (notifsJson != null) {
        final List<dynamic> decoded = json.decode(notifsJson);
        _notifications = decoded.map((json) => NotificationModel.fromMap(json)).toList();
        notifyListeners();
      } else {
        _notifications = [];
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi load thông báo: $e');
    }
  }

  Future<void> _saveNotifications() async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_notifications.map((n) => n.toMap()).toList());
      await prefs.setString('notifications_$_currentUserId', encoded);
    } catch (e) {
      print('❌ Lỗi lưu thông báo: $e');
    }
  }

  void _initSocket() {
    try {
      _socket = IO.io(ApiService.baseHost, 
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build()
      );

      _socket?.onConnect((_) {
        print('✅ App đã kết nối Real-time (Notifications)');
        if (_currentUserId != null) {
          _socket?.emit('register', _currentUserId);
        }
      });
      
      _socket?.on('new_meeting', (data) {
        _checkAndAddMeetingNotification(data, 'new');
      });

      _socket?.on('meeting_canceled', (data) {
        _checkAndAddMeetingNotification(data, 'canceled');
      });

      _socket?.on('approval_updated', (data) {
        _checkAndAddNotification(data);
      });

      _socket?.on('new_notification', (data) {
        _checkAndAddGeneralNotification(data);
      });
    } catch (e) {
      print('❌ Lỗi kết nối Socket: $e');
    }
  }

  Future<void> _checkAndAddGeneralNotification(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final user = json.decode(userData);
        final myDeptId = user['department_id'];
        final targetDepts = List<int>.from(data['target_departments'] ?? []);
        
        // Nếu targetDepts trống (gửi tất cả) hoặc có chứa phòng ban của tôi
        if (targetDepts.isEmpty || targetDepts.contains(myDeptId)) {
          _addNewNotification(
            title: '📢 Thông báo: ${data['notification']['title']}',
            body: data['notification']['content'],
            type: 'announcement',
            data: {'id': data['notification']['id']}
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi xử lý thông báo chung: $e');
    }
  }

  Future<void> _checkAndAddMeetingNotification(dynamic data, String eventType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final user = json.decode(userData);
        final myDeptId = user['department_id'];
        final targetDepts = List<int>.from(data['target_departments'] ?? []);
        
        if (targetDepts.contains(myDeptId)) {
          if (eventType == 'new') {
            _addNewNotification(
              title: '📅 Lịch họp mới: ${data['meeting']['title']}',
              body: 'Nội dung: ${data['meeting']['content']}\nĐịa điểm: ${data['meeting']['location']}',
              type: 'meeting'
            );
          } else {
            _addNewNotification(
              title: '🚫 Hủy cuộc họp: ${data['title']}',
              body: 'Cuộc họp "${data['title']}" đã bị hủy bởi quản trị viên.',
              type: 'meeting_canceled'
            );
          }
        }
      }
    } catch (e) {
      print('❌ Lỗi xử lý thông báo lịch họp: $e');
    }
  }

  Future<void> _checkAndAddNotification(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final user = json.decode(userData);
      final myId = user['id']?.toString();
      final targetId = data['employee_id']?.toString();
      
      if (myId == targetId) {
        String title = '';
        String body = '';
        String type = 'approval';
        
        final dbType = data['type']?.toString() ?? '';
        final status = data['status'] == 'approved' ? 'CHẤP THUẬN' : 'TỪ CHỐI';

        if (dbType.contains('Nghỉ phép') || dbType.contains('Nghỉ')) {
          title = 'Kết quả phê duyệt nghỉ phép';
          body = 'Đơn ${dbType.toLowerCase()} của bạn đã được $status.';
          type = 'leave_approval';
        } else if (dbType.contains('Làm thêm giờ') || dbType.contains('OT')) {
          title = 'Kết quả phê duyệt tăng ca (OT)';
          body = 'Đơn tăng ca của bạn đã được $status.';
          type = 'ot_approval';
        } else {
          title = 'Kết quả phê duyệt đơn';
          body = 'Đơn của bạn đã được $status.';
          type = 'approval';
        }

        _addNewNotification(
          title: title,
          body: body,
          type: type,
          data: {'id': data['id'], 'status': data['status']}
        );

        // Kích hoạt sự kiện refresh toàn cục cho Statistics và Leave/OT viewmodels
        NotificationEvents.emitRefresh();
      }
    }
  }

  void _addNewNotification({required String title, required String body, required String type, Map<String, dynamic>? data}) {
    final newNotif = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      data: data,
    );
    _notifications.insert(0, newNotif);
    _saveNotifications();
    NotificationService().showInstantNotification(title: title, body: body);
    notifyListeners();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final old = _notifications[idx];
      _notifications[idx] = NotificationModel(
        id: old.id,
        title: old.title,
        body: old.body,
        type: old.type,
        isRead: true,
        createdAt: old.createdAt,
      );
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        final old = _notifications[i];
        _notifications[i] = NotificationModel(
          id: old.id,
          title: old.title,
          body: old.body,
          type: old.type,
          isRead: true,
          createdAt: old.createdAt,
        );
      }
    }
    _saveNotifications();
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}

class MeetingViewModel extends ChangeNotifier {
  List<MeetingModel> _meetings = [];
  Map<int, String> _departments = {};
  bool _isLoading = false;

  List<MeetingModel> get meetings => _meetings;
  bool get isLoading => _isLoading;

  Future<void> fetchDepartments() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/departments'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _departments = { for (var d in data) d['id']: d['name'] };
        notifyListeners();
      }
    } catch (e) {
      print('❌ Lỗi FetchDepartments: $e');
    }
  }

  String getDeptName(int id) => _departments[id] ?? 'Phòng $id';

  Future<void> fetchMeetings() async {
    _isLoading = true;
    notifyListeners();
    if (_departments.isEmpty) await fetchDepartments();
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/meetings'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _meetings = data.map((m) => MeetingModel.fromMap(m)).toList();
      }
    } catch (e) {
      print('❌ Lỗi FetchMeetings: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> scheduleReminder(MeetingModel meeting) async {
    final reminderTime = meeting.startTime.subtract(const Duration(minutes: 5));
    if (reminderTime.isAfter(DateTime.now())) {
      await NotificationService().scheduleNotification(
        id: int.tryParse(meeting.id) ?? 0,
        title: '🔔 Sắp đến giờ họp!',
        body: 'Cuộc họp "${meeting.title}" sẽ bắt đầu sau 5 phút nữa.',
        scheduledDate: reminderTime,
      );
    }
  }
}

class ProfileViewModel extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  void setUser(UserModel u) {
    _user = u;
    notifyListeners();
  }

  String _selectedLanguage = 'vi';
  String get selectedLanguage => _selectedLanguage;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  Future<bool> updateAvatar(String employeeId, String avatarUrl) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/employees/avatar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'employee_id': employeeId, 'avatar_url': avatarUrl}),
      );
      if (response.statusCode == 200) {
        if (_user != null) {
          _user = UserModel(
            id: _user!.id,
            employeeCode: _user!.employeeCode,
            name: _user!.name,
            email: _user!.email,
            phone: _user!.phone,
            departmentId: _user!.departmentId,
            departmentName: _user!.departmentName,
            position: _user!.position,
            joinDate: _user!.joinDate,
            avatarUrl: avatarUrl,
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
