import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

import 'ot_detail_screen.dart';

class OTHistoryScreen extends StatefulWidget {
  const OTHistoryScreen({super.key});

  @override
  State<OTHistoryScreen> createState() => _OTHistoryScreenState();
}

class _OTHistoryScreenState extends State<OTHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();

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

  void _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'CHỌN THÁNG',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OvertimeViewModel>();
    final profileVM = context.watch<ProfileViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => key.tr();

    final filteredOvertimes = vm.overtimes.where((o) => 
      o.date.year == _selectedMonth.year && o.date.month == _selectedMonth.month
    ).toList();

    final approvedHours = filteredOvertimes
        .where((o) => o.status == 'approved')
        .fold(0.0, (sum, o) => sum + o.expectedHours);
    
    final pendingCount = filteredOvertimes.where((o) => o.status == 'pending').length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('ot_history'),
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, fontSize: 17),
        ),
        actions: [
          GestureDetector(
            onTap: () => _selectMonth(context),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.calendar_month_rounded, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : const Color(0xFF0369A1)),
                const SizedBox(width: 8),
                Text(
                  '${_selectedMonth.month}/${_selectedMonth.year}',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF0369A1), fontWeight: FontWeight.bold, fontSize: 11)
                ),
              ]),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          Text(
            'Lịch sử đăng ký OT',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 26, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Theo dõi và quản lý các yêu cầu làm thêm giờ của bạn',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'total_approved_hours'.tr(),
                  value: '${approvedHours.toStringAsFixed(1)} giờ',
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withOpacity(0.15) : const Color(0xFFE0F2FE),
                  textColor: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300]! : const Color(0xFF0369A1),
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
                  title: 'pending_requests'.tr(),
                  value: pendingCount.toString().padLeft(2, '0'),
                  subtitle: 'Đang đợi kiểm duyệt',
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.withOpacity(0.15) : const Color(0xFFFFF7ED),
                  textColor: Theme.of(context).brightness == Brightness.dark ? Colors.orange[300]! : const Color(0xFF9A3412),
                  icon: Icons.assignment_late_rounded,
                  isSecondary: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          if (vm.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (filteredOvertimes.isEmpty)
             Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(t('no_data'), style: const TextStyle(fontFamily: 'Nunito', color: Colors.grey))))
          else
            ...filteredOvertimes.map((ot) => _OTItemCard(
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
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
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
        statusBg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF064E3B).withOpacity(0.5) : const Color(0xFFECFDF5);
        statusText = 'approved'.tr();
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusBg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF7F1D1D).withOpacity(0.5) : const Color(0xFFFEF2F2);
        statusText = 'Từ chối';
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF78350F).withOpacity(0.5) : const Color(0xFFFFFBEB);
        statusText = 'Chờ duyệt';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
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
                        style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Text('${ot.expectedHours} hours', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
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
