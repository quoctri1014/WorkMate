import 'package:flutter/material.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/data/repositories/firebase_service.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  
  List<MeetingModel> _todayMeetings = [];
  List<AttendanceModel> _recentAttendance = [];
  double _monthlyHours = 0;
  int _lateDays = 0;

  List<MeetingModel> get todayMeetings => _todayMeetings;
  List<AttendanceModel> get recentAttendance => _recentAttendance;
  double get monthlyHours => _monthlyHours;
  int get lateDays => _lateDays;

  // Khởi tạo dữ liệu màn hình chính (AUDITED)
  void init(UserModel user) {
    // 1. Lắng nghe lịch họp theo phòng ban của nhân viên
    _firebase.getMeetings(user.departmentName).listen((data) {
      _todayMeetings = data;
      notifyListeners();
    });

    // 2. Lắng nghe chấm công gần đây
    _firebase.getMyAttendance(user.id).listen((data) {
      _recentAttendance = data.take(5).toList();
      
      // Tính toán thống kê tháng (Demo logic)
      _monthlyHours = data.fold(0.0, (sum, item) => sum + 8.5); 
      _lateDays = data.where((a) => a.status == 'Muộn').length;
      
      notifyListeners();
    });
  }
}
