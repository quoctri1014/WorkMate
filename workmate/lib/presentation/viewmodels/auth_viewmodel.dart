import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/data/repositories/api_service.dart';
// import 'package:workmate/data/repositories/firebase_service.dart';
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

  // Đăng nhập bằng mã nhân viên và mật khẩu (Kết nối trực tiếp PostgreSQL via Node.js)
  Future<bool> loginWithEmployeeCode(String code, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi API Backend
      final user = await _api.login(code, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        
        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(user.toMap()));
        
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

  Future<void> resetPassword(String email) async {
    // Đã chuyển sang Node.js
    throw UnimplementedError();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    // Đã chuyển sang Node.js
    throw UnimplementedError();
  }

  Future<bool> updateFaceId(List<double> embedding) async {
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
    notifyListeners();
  }
}
