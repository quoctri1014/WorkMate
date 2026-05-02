import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime? date, [String locale = 'vi']) {
    if (date == null) return 'Chưa cập nhật';
    return DateFormat('dd/MM/yyyy', locale).format(date.toLocal());
  }

  static String formatDateTime(DateTime? date, [String locale = 'vi']) {
    if (date == null) return 'Chưa cập nhật';
    return DateFormat('HH:mm - dd/MM/yyyy', locale).format(date.toLocal());
  }

  static String formatTime(DateTime date, [String locale = 'vi']) {
    return DateFormat('HH:mm', locale).format(date.toLocal());
  }

  static String formatDayMonth(DateTime date, [String locale = 'vi']) {
    if (locale == 'vi') {
      return DateFormat("dd 'Tháng' MM, yyyy", 'vi').format(date.toLocal());
    }
    return DateFormat('MMMM dd, yyyy', 'en').format(date.toLocal());
  }

  static String formatWeekday(DateTime date, [String locale = 'vi']) {
    final viDays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final enDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return locale == 'vi' ? viDays[date.toLocal().weekday % 7] : enDays[date.toLocal().weekday % 7];
  }

  static String formatRelativeTime(DateTime date, [String locale = 'vi']) {
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());
    if (locale == 'vi') {
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    } else {
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
    }
    return formatDate(date, locale);
  }

  static String formatMonthYear(DateTime date, [String locale = 'vi']) {
    if (locale == 'vi') {
      return DateFormat('Tháng MM, yyyy', 'vi').format(date.toLocal());
    }
    return DateFormat('MMMM yyyy', 'en').format(date.toLocal());
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String greetingByTime([String locale = 'vi']) {
    final hour = DateTime.now().hour;
    if (locale == 'vi') {
      if (hour >= 5 && hour < 12) return 'Chào buổi sáng';
      if (hour >= 12 && hour < 18) return 'Chào buổi chiều';
      return 'Chào buổi tối';
    } else {
      if (hour >= 5 && hour < 12) return 'Good morning';
      if (hour >= 12 && hour < 18) return 'Good afternoon';
      return 'Good evening';
    }
  }
}
