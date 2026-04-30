import 'package:flutter/material.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/data/repositories/firebase_service.dart';

class LeaveViewModel extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  bool _isLoading = false;
  List<LeaveModel> _history = [];

  bool get isLoading => _isLoading;
  List<LeaveModel> get history => _history;

  // Lắng nghe danh sách đơn từ của nhân viên
  void listenToRequests(String uid) {
    _firebase.getMyRequests(uid).listen((data) {
      _history = data;
      notifyListeners();
    });
  }

  // Gửi đơn xin nghỉ phép
  Future<bool> submitLeaveRequest({
    required UserModel user,
    required String type,
    required String reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebase.submitApprovalRequest(
        uid: user.id,
        name: user.name,
        type: type,
        reason: reason,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
