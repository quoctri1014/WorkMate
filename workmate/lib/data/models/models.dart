import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

// Bank Account Model
class BankAccount {
  final int id;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final bool isDefault;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.isDefault = false,
  });

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'] ?? 0,
      bankName: map['bank_name'] ?? '',
      accountNumber: map['account_number'] ?? '',
      accountHolder: map['account_holder'] ?? '',
      isDefault: map['is_default'] ?? false,
    );
  }
}

// User Model
class UserModel {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String role; 
  final int departmentId;
  final String departmentName;
  final String position;
  final DateTime? joinDate;
  final DateTime? birthday;
  final double baseSalary;
  final List<BankAccount> bankAccounts;
  final int seniorityPoints;
  final int technicalScore;
  final int teamworkScore;
  final int creativityScore;

  UserModel({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl = '',
    this.role = 'user',
    this.departmentId = 0,
    this.departmentName = '',
    this.position = '',
    this.joinDate,
    this.birthday,
    this.baseSalary = 0,
    this.bankAccounts = const [],
    this.seniorityPoints = 0,
    this.technicalScore = 0,
    this.teamworkScore = 0,
    this.creativityScore = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'department_id': departmentId,
      'department_name': departmentName,
      'position': position,
      'join_date': joinDate?.toIso8601String(),
      'birthday': birthday?.toIso8601String(),
      'base_salary': baseSalary,
      'seniority_points': seniorityPoints,
      'technical_score': technicalScore,
      'teamwork_score': teamworkScore,
      'creativity_score': creativityScore,
    };
  }

  String get seniorityText {
    if (joinDate == null) return '0 tháng';
    final diff = DateTime.now().difference(joinDate!);
    final years = diff.inDays ~/ 365;
    final months = (diff.inDays % 365) ~/ 30;
    if (years > 0) return '$years năm $months tháng';
    return '$months tháng';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? 0,
      employeeCode: map['employee_code'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
      role: map['role'] ?? 'user',
      departmentId: map['department_id'] ?? 0,
      departmentName: map['department_name'] ?? '',
      position: map['position'] ?? '',
      joinDate: map['join_date'] != null ? DateTime.tryParse(map['join_date'].toString()) : null,
      birthday: map['birthday'] != null ? DateTime.tryParse(map['birthday'].toString()) : null,
      baseSalary: double.tryParse(map['base_salary']?.toString() ?? '0') ?? 0,
      bankAccounts: map['bankAccounts'] != null 
          ? (map['bankAccounts'] as List).map((x) => BankAccount.fromMap(x)).toList()
          : [],
      seniorityPoints: map['seniority_points'] ?? 0,
      technicalScore: map['technical_score'] ?? 0,
      teamworkScore: map['teamwork_score'] ?? 0,
      creativityScore: map['creativity_score'] ?? 0,
    );
  }
}

// Attendance Model
class AttendanceModel {
  final String id;
  final String userId;
  final String employeeName;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String method; 
  final String status;
  final String? shiftName;
  final double workedHours;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.method,
    required this.status,
    this.shiftName,
    this.workedHours = 0,
  });

  String get statusLabel {
    switch(status) {
      case 'ontime': return 'Đúng giờ';
      case 'late': return 'Đi muộn';
      case 'holiday': return 'Ngày lễ';
      default: return status;
    }
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.parse(d);
      return DateTime.now();
    }
    
    DateTime? parseDateNullable(dynamic d) {
      if (d == null) return null;
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.parse(d);
      return null;
    }

    return AttendanceModel(
      id: docId,
      userId: (map['uid'] ?? map['employee_id'] ?? '').toString(),
      employeeName: map['employeeName'] ?? map['name'] ?? '',
      date: parseDate(map['check_in_time'] ?? map['created_at'] ?? map['createdAt']),
      checkIn: parseDateNullable(map['check_in_time'] ?? map['checkIn']),
      checkOut: parseDateNullable(map['check_out_time'] ?? map['checkOut']),
      method: map['method'] ?? map['check_in_method'] ?? 'WiFi',
      status: map['status'] ?? 'Hợp lệ',
      shiftName: map['shiftName'],
      workedHours: double.tryParse(map['workedHours']?.toString() ?? '0') ?? 0,
    );
  }
}

// Leave Model
class LeaveModel {
  final String id;
  final String userId;
  final String userName;
  final String leaveType; 
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String> attachments;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final bool isHalfDay;

  LeaveModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.leaveType,
    required this.reason,
    this.status = 'pending',
    required this.createdAt,
    required this.fromDate,
    required this.toDate,
    this.attachments = const [],
    this.reviewedBy,
    this.reviewedAt,
    this.isHalfDay = false,
  });

  double get totalDays {
    if (isHalfDay) return 0.5;
    return (toDate.difference(fromDate).inDays + 1).toDouble();
  }
  String get leaveTypeLabel {
    switch(leaveType) {
      case 'annual': return 'Nghỉ phép năm';
      case 'sick': return 'Nghỉ ốm';
      case 'personal': return 'Việc riêng';
      default: return leaveType;
    }
  }
  String get statusLabel => status == 'pending' ? 'Chờ duyệt' : (status == 'approved' ? 'Đã duyệt' : 'Từ chối');

  factory LeaveModel.fromMap(Map<String, dynamic> map) {
    return LeaveModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['employee_id'] ?? map['uid'] ?? '').toString(),
      userName: map['employee_name'] ?? map['name'] ?? '',
      leaveType: map['type'] ?? 'Nghỉ phép',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : (map['createdAt'] != null ? (map['createdAt'] is String ? DateTime.parse(map['createdAt']) : DateTime.now()) : DateTime.now()),
      fromDate: map['from_date'] != null ? DateTime.parse(map['from_date']) : (map['fromDate'] != null ? (map['fromDate'] is String ? DateTime.parse(map['fromDate']) : DateTime.now()) : DateTime.now()),
      toDate: map['to_date'] != null ? DateTime.parse(map['to_date']) : (map['toDate'] != null ? (map['toDate'] is String ? DateTime.parse(map['toDate']) : DateTime.now()) : DateTime.now()),
      attachments: map['attachment_urls'] is String 
          ? List<String>.from(jsonDecode(map['attachment_urls'])) 
          : List<String>.from(map['attachment_urls'] ?? map['attachments'] ?? []),
      reviewedBy: map['reviewed_by'],
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      isHalfDay: map['is_half_day'] ?? map['isHalfDay'] ?? false,
    );
  }
}

// Overtime Model
class OvertimeModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final double expectedHours;
  final String workContent;
  final String status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectReason;

  OvertimeModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.expectedHours,
    required this.workContent,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectReason,
  });

  String get statusLabel => status == 'pending' ? 'Chờ duyệt' : (status == 'approved' ? 'Đã duyệt' : 'Từ chối');

  factory OvertimeModel.fromMap(Map<String, dynamic> map) {
    return OvertimeModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['uid'] ?? map['user_id'] ?? '').toString(),
      userName: map['userName'] ?? map['user_name'] ?? '',
      date: map['date'] != null 
          ? (map['date'] is String ? DateTime.parse(map['date']) : (map['date'] as Timestamp).toDate()) 
          : DateTime.now(),
      expectedHours: double.tryParse(map['expectedHours']?.toString() ?? map['expected_hours']?.toString() ?? map['total_hours']?.toString() ?? '0') ?? 0,
      workContent: map['workContent'] ?? map['work_content'] ?? map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is String ? DateTime.parse(map['createdAt']) : (map['createdAt'] as Timestamp).toDate()) 
          : DateTime.now(),
      reviewedBy: map['reviewedBy'] ?? map['reviewed_by'],
      reviewedAt: map['reviewedAt'] != null 
          ? (map['reviewedAt'] is String ? DateTime.parse(map['reviewedAt']) : (map['reviewedAt'] as Timestamp).toDate()) 
          : null,
      rejectReason: map['rejectReason'] ?? map['reject_reason'],
    );
  }
}

// Meeting Model
class MeetingModel {
  final String id;
  final String title;
  final String content;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final bool isOnline;
  final List<int> departmentIds;
  final String? meetLink;
  final int participantCount;
  final String? organizerId;
  final String? organizerName;

  MeetingModel({
    required this.id,
    required this.title,
    this.content = '',
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.isOnline,
    this.departmentIds = const [],
    this.meetLink,
    this.participantCount = 0,
    this.organizerId,
    this.organizerName,
  });

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      startTime: map['start_time'] != null ? DateTime.parse(map['start_time']) : DateTime.now(),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : DateTime.now().add(const Duration(hours: 1)),
      location: map['location'] ?? '',
      isOnline: map['is_online'] ?? false,
      departmentIds: map['department_ids'] is String 
          ? List<int>.from(jsonDecode(map['department_ids'])) 
          : List<int>.from(map['department_ids'] ?? []),
      meetLink: map['meet_link'],
      participantCount: map['participant_count'] ?? 0,
      organizerId: map['organizer_id'],
      organizerName: map['organizer_name'],
    );
  }
}

// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: (map['id'] ?? '').toString(),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      isRead: map['isRead'] ?? map['is_read'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : (map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now()),
      data: map['data'],
    );
  }
}

// Company Config Model
class CompanyConfigModel {
  final int id;
  final String companyName;
  final double? safeLat;
  final double? safeLng;
  final String? safeWifiSsid;

  CompanyConfigModel({
    required this.id,
    required this.companyName,
    this.safeLat,
    this.safeLng,
    this.safeWifiSsid,
  });

  factory CompanyConfigModel.fromMap(Map<String, dynamic> map) {
    return CompanyConfigModel(
      id: map['id'] ?? 0,
      companyName: map['company_name'] ?? 'QUẬN 12',
      safeLat: double.tryParse(map['safe_lat']?.toString() ?? ''),
      safeLng: double.tryParse(map['safe_lng']?.toString() ?? ''),
      safeWifiSsid: map['safe_wifi_ssid'],
    );
  }
}
