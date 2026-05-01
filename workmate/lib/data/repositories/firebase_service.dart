import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmate/data/models/models.dart';

class FirebaseService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // --- AUTH SERVICE ---
  
  Future<UserModel?> loginWithCode(String code, String password) async {
    try {
      final snap = await _db.collection('employees')
          .where('employeeCode', isEqualTo: code)
          .get();

      if (snap.docs.isEmpty) throw Exception("Mã nhân viên không tồn tại");

      final userData = snap.docs.first.data();
      final email = userData['email'];

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      return UserModel.fromMap(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // --- ATTENDANCE SERVICE ---

  Future<void> submitAttendance({
    required String uid,
    required String name,
    required String method,
    double? lat,
    double? lng,
  }) async {
    await _db.collection('attendance').add({
      'uid': uid,
      'employeeName': name,
      'checkIn': FieldValue.serverTimestamp(),
      'method': method,
      'status': 'ontime', // Mặc định là đúng giờ, Web có thể duyệt lại
      'lat': lat,
      'lng': lng,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AttendanceModel>> getMyAttendance(String uid) {
    return _db.collection('attendance')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AttendanceModel.fromMap(d.data(), d.id)).toList());
  }

  // --- LEAVE & APPROVALS ---

  Future<void> submitApprovalRequest({
    required String uid,
    required String name,
    required String type, 
    required String reason,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await _db.collection('approvals').add({
      'uid': uid,
      'name': name,
      'type': type,
      'reason': reason,
      'status': 'pending',
      'fromDate': fromDate != null ? Timestamp.fromDate(fromDate) : null,
      'toDate': toDate != null ? Timestamp.fromDate(toDate) : null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<LeaveModel>> getMyRequests(String uid) {
    return _db.collection('approvals')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => LeaveModel.fromMap(d.data() as Map<String, dynamic>)).toList());
  }

  // --- MEETINGS & SETTINGS ---

  Stream<List<MeetingModel>> getMeetings(int myDeptId) {
    return _db.collection('meetings')
        .snapshots()
        .map((s) => s.docs
            .map((d) => MeetingModel.fromMap(d.data()))
            .where((m) => m.departmentIds.isEmpty || m.departmentIds.contains(myDeptId))
            .toList());
  }

  Future<Map<String, dynamic>?> getOfficeSettings() async {
    final snap = await _db.collection('settings').doc('attendance').get();
    return snap.data();
  }
}
