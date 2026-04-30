import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'package:workmate/presentation/views/notification/announcement_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'leave_approval':
      case 'ot_approval':
      case 'approval': return Icons.check_circle_outline_rounded;
      case 'reminder': return Icons.alarm_rounded;
      case 'update': return Icons.system_update_rounded;
      case 'meeting_canceled': return Icons.cancel_presentation_rounded;
      case 'announcement': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'leave_approval':
      case 'ot_approval':
      case 'approval': return AppColors.success;
      case 'reminder': return AppColors.warning;
      case 'update': return AppColors.primary;
      case 'meeting_canceled': return AppColors.error;
      case 'announcement': return Colors.amber[600]!;
      default: return AppColors.textSecondary;
    }
  }

  void _showNotificationDetail(BuildContext context, NotificationModel notif, NotificationViewModel vm) {
    if (!notif.isRead) vm.markAsRead(notif.id);
    
    // Xử lý điều hướng dựa trên type
    void handleNavigation() {
      print('🚀 [Notification] Navigating for type: ${notif.type}');
      Navigator.pop(context); // Đóng BottomSheet trước
      
      switch (notif.type) {
        case 'leave_approval':
          print('📌 [Notification] Pushing to Leave History');
          Navigator.pushNamed(context, AppRoutes.leaveHistory);
          break;
        case 'ot_approval':
          print('📌 [Notification] Pushing to OT History');
          Navigator.pushNamed(context, AppRoutes.otHistory);
          break;
        case 'meeting':
          print('📌 [Notification] Pushing to Meeting List');
          Navigator.pushNamed(context, AppRoutes.meeting);
          break;
        case 'announcement':
          print('📌 [Notification] Pushing to Announcement Detail');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailScreen(notification: notif),
            ),
          );
          break;
        case 'approval':
          print('📌 [Notification] Fallback check for type: approval');
          if (notif.title.contains('nghỉ phép')) {
            Navigator.pushNamed(context, AppRoutes.leaveHistory);
          } else if (notif.title.contains('OT') || notif.title.contains('tăng ca')) {
            Navigator.pushNamed(context, AppRoutes.otHistory);
          } else {
            Navigator.pushNamed(context, AppRoutes.leaveHistory);
          }
          break;
        default:
          print('⚠️ [Notification] No navigation defined for type: ${notif.type}');
          break;
      }
    }

    final isMeetingCanceled = notif.type == 'meeting_canceled';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (isMeetingCanceled ? AppColors.error : _typeColor(notif.type)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isMeetingCanceled ? Icons.cancel_presentation_rounded : _typeIcon(notif.type), 
                    color: isMeetingCanceled ? AppColors.error : _typeColor(notif.type),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif.title, 
                        style: TextStyle(
                          fontFamily: 'Nunito', 
                          fontSize: 18, 
                          fontWeight: FontWeight.w900, 
                          color: isMeetingCanceled ? AppColors.error : AppColors.textPrimary
                        )
                      ),
                      Text(AppDateUtils.formatRelativeTime(notif.createdAt), style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMeetingCanceled) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.error.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                notif.body,
                                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        notif.body,
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, height: 1.6, color: AppColors.textPrimary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: handleNavigation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMeetingCanceled ? AppColors.textSecondary : AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: Text(
                  isMeetingCanceled ? 'Đóng' : 'Xem chi tiết', 
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final profileVM = context.watch<ProfileViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, automaticallyImplyLeading: false,
        title: Text(t('notifications'), style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 20)),
        actions: [
          TextButton(onPressed: vm.markAllAsRead, child: Text(t('mark_all_read'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.primary))),
        ],
      ),
      body: Column(children: [
        // Pinned banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('new_update'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(t('new_update_desc'),
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, color: Colors.white70, height: 1.4)),
            ])),
          ]),
        ),

        // Notification list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (vm.notifications.any((n) => AppDateUtils.isToday(n.createdAt))) ...[
                _SectionHeader(t('today')),
                ...vm.notifications.where((n) => AppDateUtils.isToday(n.createdAt)).map((n) => _NotifCard(
                  notif: n, typeIcon: _typeIcon(n.type), typeColor: _typeColor(n.type),
                  onTap: () => _showNotificationDetail(context, n, vm),
                )),
              ],
              if (vm.notifications.any((n) => !AppDateUtils.isToday(n.createdAt) && 
                  AppDateUtils.isYesterday(n.createdAt))) ...[
                const SizedBox(height: 8),
                _SectionHeader(t('yesterday')),
                ...vm.notifications.where((n) => AppDateUtils.isYesterday(n.createdAt)).map((n) => _NotifCard(
                  notif: n, typeIcon: _typeIcon(n.type), typeColor: _typeColor(n.type),
                  onTap: () => _showNotificationDetail(context, n, vm),
                )),
              ],
              if (vm.notifications.any((n) => !AppDateUtils.isToday(n.createdAt) && 
                  !AppDateUtils.isYesterday(n.createdAt))) ...[
                const SizedBox(height: 8),
                _SectionHeader(t('this_week')),
                ...vm.notifications.where((n) => !AppDateUtils.isToday(n.createdAt) && 
                    !AppDateUtils.isYesterday(n.createdAt)).map((n) => _NotifCard(
                  notif: n, typeIcon: _typeIcon(n.type), typeColor: _typeColor(n.type),
                  onTap: () => _showNotificationDetail(context, n, vm),
                )),
              ],
              const SizedBox(height: 20),
              // Promo banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                child: Column(children: [
                  Container(height: 80, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 36))),
                  const SizedBox(height: 12),
                  Text(t('welcome_version'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(t('welcome_desc'), textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 40,
                    child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text(t('explore_now'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)))),
                ]),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
  );
}

class _NotifCard extends StatelessWidget {
  final dynamic notif;
  final IconData typeIcon;
  final Color typeColor;
  final VoidCallback onTap;
  const _NotifCard({required this.notif, required this.typeIcon, required this.typeColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notif.isRead ? Colors.white : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: notif.isRead ? Border.all(color: AppColors.border) : Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: notif.isRead ? [] : AppColors.cardShadow,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(typeIcon, color: typeColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(notif.title, style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w700, color: AppColors.textPrimary))),
            if (!notif.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 4),
          Text(notif.body, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(AppDateUtils.formatRelativeTime(notif.createdAt), style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, color: AppColors.textHint)),
        ])),
      ]),
    ),
  );
}
