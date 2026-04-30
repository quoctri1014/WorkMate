import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmate/presentation/views/attendance/checkin_permission_screen.dart';
import 'package:workmate/presentation/views/attendance/checkin_face_screen.dart';
import 'package:workmate/presentation/views/schedule/schedule_screen.dart';
import 'package:workmate/presentation/views/leave/leave_request_screen.dart';
import 'package:workmate/presentation/views/leave/leave_history_screen.dart';
import 'package:workmate/presentation/views/overtime/ot_request_screen.dart';
import 'package:workmate/presentation/views/overtime/ot_history_screen.dart';
import 'package:workmate/presentation/views/meeting/meeting_screen.dart';
import 'package:workmate/presentation/views/profile/personal_info_screen.dart';
import 'package:workmate/presentation/views/profile/seniority_screen.dart';
import 'package:workmate/core/i18n/app_translations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  String _timeStr = '';
  String _dateStr = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    final profileVM = context.read<ProfileViewModel>();
    final lang = profileVM.selectedLanguage;
    setState(() {
      _timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _dateStr = AppDateUtils.formatDayMonth(now, lang);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final profileVM = context.watch<ProfileViewModel>();
    final user = homeVM.user;
    final lang = profileVM.selectedLanguage;

    String t(String key) => AppTranslations.getText(lang, key);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Update date string on build to reflect language change immediately
    _dateStr = AppDateUtils.formatDayMonth(DateTime.now(), lang);

    // Xử lý URL ảnh
    String avatarUrl = user.avatarUrl;
    if (avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      avatarUrl = 'http://10.0.2.2:5000$avatarUrl';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      // Top row: avatar + greeting
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl.isEmpty 
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppDateUtils.greetingByTime(lang)},',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${user.employeeCode} • $_dateStr',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Check-in Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: Colors.white,
                                      size: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  t('attendance'),
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                // Time display
                                Text(
                                  _timeStr,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _TimeBox(
                                  label: t('check_in'),
                                  time: homeVM.checkInTime != null
                                      ? AppDateUtils.formatTime(
                                          homeVM.checkInTime!, lang)
                                      : '-- : --',
                                ),
                                const SizedBox(width: 8),
                                _TimeBox(
                                  label: t('check_out'),
                                  time: homeVM.checkOutTime != null
                                      ? AppDateUtils.formatTime(
                                          homeVM.checkOutTime!, lang)
                                      : '-- : --',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Check In/Out Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: homeVM.isCheckingIn
                                    ? null
                                    : () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        final isGranted = prefs.getBool('permissions_granted') ?? false;
                                        
                                        if (isGranted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CheckInFaceScreen(isCheckIn: !homeVM.isCheckedIn),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const CheckInPermissionScreen(),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: homeVM.isCheckedIn
                                      ? const Color(0xFF2C7BAE)
                                      : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: homeVM.isCheckingIn
                                    ? const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      )
                                    : Text(
                                        homeVM.isCheckedIn
                                            ? 'CHECK OUT'
                                            : 'CHECK IN',
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: homeVM.isCheckedIn
                                              ? Colors.white
                                              : AppColors.primary,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  t('company_location'),
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Workspace
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Text(
                    t('workspace'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_horiz_rounded,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate(
                _workspaceItems(context, t),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _workspaceItems(BuildContext context, String Function(String) t) {
    final items = [
      _WorkspaceCard(
        icon: Icons.calendar_today_rounded,
        color: AppColors.wsSchedule,
        title: t('work_schedule'),
        subtitle: t('view_shifts'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ScheduleScreen())),
      ),
      _WorkspaceCard(
        icon: Icons.beach_access_rounded,
        color: AppColors.wsLeave,
        title: t('leave_request'),
        subtitle: t('create_leave'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LeaveRequestScreen())),
      ),
      _WorkspaceCard(
        icon: Icons.groups_rounded,
        color: AppColors.wsMeeting,
        title: t('meeting_schedule'),
        subtitle: t('meeting_detail'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MeetingScreen())),
      ),
      _WorkspaceCard(
        icon: Icons.more_time_rounded,
        color: AppColors.wsOT,
        title: t('ot_request'),
        subtitle: t('add_work_hours'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OTRequestScreen())),
      ),
      _WorkspaceCard(
        icon: Icons.history_rounded,
        color: AppColors.wsOTHistory,
        title: t('ot_history'),
        subtitle: t('search_ot'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OTHistoryScreen())),
      ),
      _WorkspaceCard(
        icon: Icons.event_busy_rounded,
        color: AppColors.wsLeaveHistory,
        title: t('leave_history'),
        subtitle: t('track_leave'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LeaveHistoryScreen())),
      ),
      _WorkspaceCard(
        icon: Icons.emoji_events_rounded,
        color: AppColors.wsSeniority,
        title: t('seniority_text'),
        subtitle: t('dedication'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SeniorityScreen())),
      ),
      _WorkspaceCard(
        icon: Icons.person_rounded,
        color: AppColors.wsProfile,
        title: t('personal_profile'),
        subtitle: t('account_management'),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
      ),
    ];
    return items;
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String time;

  const _TimeBox({required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WorkspaceCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
