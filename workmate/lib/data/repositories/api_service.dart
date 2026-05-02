import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:workmate/data/models/models.dart';

class ApiService {
  // Tự động nhận diện IP cho Android Emulator (10.0.2.2) và iOS thực tế (Dùng IP máy tính)
  static String get baseHost {
    if (Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://172.20.10.2:5000'; // IP máy tính khi kết nối Điểm truy cập cá nhân từ iPhone
  }

  static String get baseUrl => '$baseHost/api';

  Future<UserModel?> login(String code, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data['user']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTodayAttendance(int employeeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/attendance/today/$employeeId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<LeaveModel>> getLeaveHistory(String employeeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/approvals?employee_id=$employeeId'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => LeaveModel.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Lỗi getLeaveHistory: $e');
      return [];
    }
  }

  Future<List<List<double>>?> fetchSavedEmbedding(int employeeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/face/embedding/$employeeId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['embeddings'] != null) {
          return (data['embeddings'] as List)
              .map((e) => (e as List).cast<double>())
              .toList();
        }
        return [(data['embedding'] as List).cast<double>()];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> submitCheckIn(int employeeId, List<double> embedding, String action, {double? lat, double? lng, String? wifiSsid}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/face/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_id': employeeId,
          'embedding': embedding,
          'action': action,
          'lat': lat,
          'lng': lng,
          'wifi_ssid': wifiSsid,
        }),
      );
      
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Chấm công thành công'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<bool> registerFace(int employeeId, dynamic embeddings) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/face/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_id': employeeId,
          'embeddings': embeddings,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<CompanyConfigModel?> getCompanyConfig() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/company/config'));
      if (response.statusCode == 200) {
        return CompanyConfigModel.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> getUserByCode(String code) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/employees/code/$code'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<BankAccount>> getEmployeeBanks(int employeeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/employees/$employeeId/banks'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((x) => BankAccount.fromMap(x)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<BankAccount?> addEmployeeBank(int employeeId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$employeeId/banks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return BankAccount.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<BankAccount?> updateEmployeeBank(int bankId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/employees/banks/$bankId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return BankAccount.fromMap(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteEmployeeBank(int bankId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/employees/banks/$bankId'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
