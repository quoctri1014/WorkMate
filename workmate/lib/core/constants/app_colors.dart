import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF1C6185);
  static const Color primaryLight = Color(0xFF9AD6FF);
  static const Color secondary = Color(0xFFBAE2FE);
  static const Color primarySurface = Color(0xFFE8F4FD);

  // Background
  static const Color background = Color(0xFFF5F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1C6185);
  static const Color textSecondary = Color(0xFF595C5E);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFB300);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Attendance Status
  static const Color statusOnTime = Color(0xFF4CAF50);
  static const Color statusLate = Color(0xFFFF9800);
  static const Color statusAbsent = Color(0xFFF44336);
  static const Color statusHoliday = Color(0xFF9C27B0);
  static const Color statusLeave = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4A9FD5), Color(0xFF2C7BAE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF5BA8D8), Color(0xFF3D8BBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> loginGradient = [
    Color(0xFFBAE2FE),
    Color(0xFFFFFFFF),
  ];

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF4A9FD5).withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: const Color(0xFF4A9FD5).withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Workspace icon colors
  static const Color wsSchedule = Color(0xFF4A9FD5);
  static const Color wsLeave = Color(0xFFFF6B6B);
  static const Color wsMeeting = Color(0xFF9C27B0);
  static const Color wsOT = Color(0xFF4CAF50);
  static const Color wsOTHistory = Color(0xFFFF9800);
  static const Color wsLeaveHistory = Color(0xFF2196F3);
  static const Color wsSeniority = Color(0xFF9C27B0);
  static const Color wsProfile = Color(0xFF607D8B);

  // Divider
  static const Color divider = Color(0xFFECF0F5);
  static const Color border = Color(0xFFDDE4EE);
}
