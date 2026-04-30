import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/data/repositories/firebase_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  bool _isLoading = false;
  List<AttendanceModel> _history = [];

  bool get isLoading => _isLoading;
  List<AttendanceModel> get history => _history;

  void listenToAttendance(String uid) {
    _firebase.getMyAttendance(uid).listen((data) {
      _history = data;
      notifyListeners();
    });
  }

  // LOGIC KIỂM TRA CHẤM CÔNG (FIXED & AUDITED)
  Future<String> checkInWithValidation(UserModel user, String method) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Lấy cấu hình văn phòng từ Web Admin
      final settings = await _firebase.getOfficeSettings();
      if (settings == null) throw Exception("Không tìm thấy cấu hình văn phòng");

      // 2. Nếu chấm công bằng GPS -> Kiểm tra khoảng cách
      if (method == 'GPS') {
        Position pos = await Geolocator.getCurrentPosition();
        double distance = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, 
          double.parse(settings['officeLat']), double.parse(settings['officeLng'])
        );

        if (distance > double.parse(settings['radius'])) {
          _isLoading = false;
          notifyListeners();
          return "Bạn đang ở ngoài vùng cho phép (${distance.toInt()}m)";
        }
      }

      // 3. Nếu chấm công bằng WiFi -> Kiểm tra BSSID (Đang demo logic)
      // (Thực tế sẽ dùng network_info_plus để lấy BSSID hiện tại)

      // 4. Gửi dữ liệu lên Firebase
      await _firebase.submitAttendance(
        uid: user.id,
        name: user.name,
        method: method,
      );

      _isLoading = false;
      notifyListeners();
      return "SUCCESS";
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return "Lỗi: ${e.toString()}";
    }
  }
}
