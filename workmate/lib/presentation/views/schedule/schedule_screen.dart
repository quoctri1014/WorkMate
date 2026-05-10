import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    
    // Load data when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<StatisticsViewModel>().fetchStatistics(user.id);
        context.read<LeaveViewModel>().fetchLeaves(user.id);
      }
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final statsVM = context.watch<StatisticsViewModel>();
    final leaveVM = context.watch<LeaveViewModel>();
    final homeVM = context.watch<HomeViewModel>();
    
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);

    final history = statsVM.attendanceHistory;
    final leaves = leaveVM.leaves.where((l) => l.status == 'approved').toList();
    final config = homeVM.companyConfig;

    AttendanceModel? getAttendanceForDay(DateTime day) {
      final att = history.where((a) => _isSameDay(a.date.toLocal(), day)).toList();
      return att.isNotEmpty ? att.first : null;
    }

    bool hasLeaveOnDay(DateTime day) {
      // Check leave requests (Only "Nghỉ" types)
      final hasLeaveReq = leaves.any((l) => 
        l.leaveType.contains('Nghỉ') &&
        (day.isAtSameMomentAs(l.fromDate) || day.isAfter(l.fromDate)) && 
        (day.isAtSameMomentAs(l.toDate) || day.isBefore(l.toDate.add(const Duration(hours: 23, minutes: 59))))
      );
      if (hasLeaveReq) return true;

      // Check non-working days
      if (config != null && config.work_days != null) {
        try {
          final List<dynamic> workDays = List<dynamic>.from(json.decode(config.work_days!));
          return !workDays.contains(day.weekday);
        } catch (e) {
          return false;
        }
      }
      return false;
    }

    // Helper to get day status
    String getDayStatus(DateTime day) {
      final attendance = getAttendanceForDay(day);
      
      // 1. If attendance exists, show as ontime or late
      if (attendance != null) {
        if (config != null && attendance.checkIn != null) {
          final workStartStr = config.work_start_time ?? '08:00';
          final parts = workStartStr.split(':');
          final workStart = DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));
          
          if (attendance.checkIn!.isAfter(workStart.add(const Duration(minutes: 1)))) {
            return 'late';
          }
        }
        return 'ontime';
      }

      // 2. Check for approved leave (Only "Nghỉ" types)
      final hasLeave = leaves.any((l) => 
        l.leaveType.contains('Nghỉ') &&
        (day.isAtSameMomentAs(l.fromDate) || day.isAfter(l.fromDate)) && 
        (day.isAtSameMomentAs(l.toDate) || day.isBefore(l.toDate.add(const Duration(hours: 23, minutes: 59))))
      );
      if (hasLeave) return 'leave';

      // 3. Check if it's a non-working day from config
      if (config != null && config.work_days != null) {
        try {
          final List<dynamic> workDays = List<dynamic>.from(json.decode(config.work_days!));
          if (!workDays.contains(day.weekday)) {
            return 'leave'; // Show as Red for non-working days
          }
        } catch (e) {
          debugPrint('Error parsing work_days: $e');
        }
      }

      return 'none';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('work_schedule'),
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: TableCalendar(
              locale: lang == 'vi' ? 'vi_VN' : 'en_US',
              firstDay: DateTime(2024, 1, 1),
              lastDay: DateTime(2026, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                weekendTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey),
              ),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final status = getDayStatus(day);
                  return _buildDayWidget(day, status, isSelected: false);
                },
                selectedBuilder: (context, day, focusedDay) {
                  final status = getDayStatus(day);
                  return _buildDayWidget(day, status, isSelected: true);
                },
                todayBuilder: (context, day, focusedDay) {
                   final status = getDayStatus(day);
                   return _buildDayWidget(day, status, isToday: true);
                },
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: AppColors.success, label: 'Đúng giờ'),
                const SizedBox(width: 16),
                _LegendItem(color: AppColors.warning, label: 'Đi muộn'),
                const SizedBox(width: 16),
                _LegendItem(color: AppColors.error, label: 'Nghỉ phép'),
              ],
            ),
          ),

          // Detail Section
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHI TIẾT NGÀY ${AppDateUtils.formatDate(_selectedDay ?? DateTime.now()).toUpperCase()}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),
                  _buildDayDetail(_selectedDay ?? DateTime.now(), getAttendanceForDay, hasLeaveOnDay),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayWidget(DateTime day, String status, {bool isSelected = false, bool isToday = false}) {
    Color? bgColor;
    Color textColor = AppColors.textPrimary;
    
    if (status == 'leave') bgColor = AppColors.error;
    else if (status == 'late') bgColor = AppColors.warning;
    else if (status == 'ontime') bgColor = AppColors.success;

    if (bgColor != null) textColor = Colors.white;
    if (isSelected) {
      return Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : bgColor,
            shape: BoxShape.circle,
            border: isSelected && bgColor != null ? Border.all(color: bgColor, width: 2) : null,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor?.withOpacity(0.9),
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: isToday || bgColor != null ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayDetail(DateTime day, Function getAtt, Function hasLeave) {
    final AttendanceModel? att = getAtt(day);
    final bool leave = hasLeave(day);

    // 1. If attendance exists, always show work time details first
    if (att != null) {
      return Column(
        children: [
          _buildTimeTile(
            icon: Icons.login_rounded,
            color: AppColors.success,
            label: 'GIỜ VÀO',
            time: att.checkIn != null ? AppDateUtils.formatTime(att.checkIn!) : '--:--',
            method: att.method,
          ),
          const SizedBox(height: 12),
          _buildTimeTile(
            icon: Icons.logout_rounded,
            color: AppColors.error,
            label: 'GIỜ RA',
            time: att.checkOut != null ? AppDateUtils.formatTime(att.checkOut!) : '--:--',
            method: att.checkOut != null ? att.method : null,
          ),
        ],
      );
    }

    // 2. If no attendance but it's a leave/non-working day
    if (leave) {
      return _buildInfoTile(
        icon: Icons.beach_access_rounded,
        color: AppColors.error,
        title: 'Ngày nghỉ phép',
        subtitle: 'Bạn không có lịch làm việc hôm nay',
      );
    }

    // 3. No data at all
    return _buildInfoTile(
      icon: Icons.event_busy_rounded,
      color: Colors.grey,
      title: 'Không có dữ liệu',
      subtitle: 'Chưa có thông tin chấm công ngày này',
    );
  }

  Widget _buildInfoTile({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({required IconData icon, required Color color, required String label, required String time, String? method}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            ],
          ),
          const Spacer(),
          if (method != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Text(method, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
      ],
    );
  }
}
