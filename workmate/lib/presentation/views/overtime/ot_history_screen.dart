import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'ot_detail_screen.dart';

class OTHistoryScreen extends StatefulWidget {
  const OTHistoryScreen({super.key});

  @override
  State<OTHistoryScreen> createState() => _OTHistoryScreenState();
}

class _OTHistoryScreenState extends State<OTHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVM = context.read<HomeViewModel>();
      if (homeVM.user != null) {
        context.read<OvertimeViewModel>().fetchOvertimes(homeVM.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OvertimeViewModel>();
    final profileVM = context.watch<ProfileViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);

    final approvedHours = vm.overtimes
        .where((o) => o.status == 'approved')
        .fold(0.0, (sum, o) => sum + o.expectedHours);
    
    final pendingCount = vm.overtimes.where((o) => o.status == 'pending').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('ot_history'),
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text(
            'Lịch sử đăng ký OT',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Theo dõi và quản lý các yêu cầu làm thêm giờ của bạn',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'TỔNG GIỜ ĐÃ DUYỆT',
                  value: '${approvedHours.toStringAsFixed(1)} giờ',
                  color: const Color(0xFFE0F2FE),
                  textColor: const Color(0xFF0369A1),
                  icon: Icons.insights_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'YÊU CẦU ĐANG CHỜ',
                  value: pendingCount.toString().padLeft(2, '0'),
                  subtitle: 'Đang đợi kiểm duyệt',
                  color: const Color(0xFFFFF7ED),
                  textColor: const Color(0xFF9A3412),
                  icon: Icons.assignment_late_rounded,
                  isSecondary: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          if (vm.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (vm.overtimes.isEmpty)
             Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(t('no_data'), style: const TextStyle(fontFamily: 'Nunito', color: Colors.grey))))
          else
            ...vm.overtimes.map((ot) => _OTItemCard(
                  ot: ot,
                  t: t,
                  lang: lang,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OTDetailScreen(ot: ot))),
                )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final Color textColor;
  final IconData icon;
  final bool isSecondary;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    required this.textColor,
    required this.icon,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: textColor.withOpacity(0.7), letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value.split(' ')[0], style: TextStyle(fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900, color: textColor)),
                    if (value.contains(' ')) ...[
                      const SizedBox(width: 6),
                      Text(value.split(' ')[1], style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700, color: textColor.withOpacity(0.8))),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFDBA74), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(subtitle!, style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: textColor.withOpacity(0.8))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: textColor, size: 28),
          ),
        ],
      ),
    );
  }
}

class _OTItemCard extends StatelessWidget {
  final OvertimeModel ot;
  final String Function(String) t;
  final String lang;
  final VoidCallback onTap;

  const _OTItemCard({required this.ot, required this.t, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = ot.date;
    final monthStr = _getMonthName(date.month);
    final dayStr = date.day.toString().padLeft(2, '0');

    Color statusColor;
    String statusText;
    Color statusBg;

    switch (ot.status) {
      case 'approved':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        statusText = 'Từ chối';
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFFFBEB);
        statusText = 'Chờ duyệt';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(monthStr, style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w900, color: statusColor.withOpacity(0.6))),
                      Text(dayStr, style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: statusColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ot.workContent.isEmpty ? 'Làm thêm giờ' : ot.workContent,
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text('${ot.expectedHours} hours', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(statusText, style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w800, color: statusColor)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}
