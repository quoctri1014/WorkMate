import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'package:workmate/data/models/models.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1;
  String _selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVM = context.read<HomeViewModel>();
      if (homeVM.user != null) {
        context.read<StatisticsViewModel>().fetchStatistics(homeVM.user!.id, period: _selectedPeriod);
      }
    });
  }

  void _selectWeek(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.primary)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Tìm ngày thứ 2 của tuần chứa ngày picked
      final int dayOfWeek = picked.weekday; // 1: Mon, ..., 7: Sun
      final DateTime monday = picked.subtract(Duration(days: dayOfWeek - 1));
      final DateTime sunday = monday.add(const Duration(days: 6));

      final homeVM = context.read<HomeViewModel>();
      if (homeVM.user != null) {
        context.read<StatisticsViewModel>().fetchStatistics(
          homeVM.user!.id, 
          startDate: monday, 
          endDate: sunday
        );
      }
      
      setState(() {
        _selectedPeriod = '${AppDateUtils.formatDate(monday)} - ${AppDateUtils.formatDate(sunday)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();
    final profileVM = context.watch<ProfileViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          final homeVM = context.read<HomeViewModel>();
          if (homeVM.user != null) {
            await context.read<StatisticsViewModel>().fetchStatistics(homeVM.user!.id, period: _selectedPeriod);
          }
        },
        child: vm.isLoading && vm.attendanceHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.white,
                floating: true,
                pinned: true,
                elevation: 0,
                centerTitle: false,
                title: Text(t('attendance_analysis'), 
                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 22)),
                actions: [
                  GestureDetector(
                    onTap: () => _selectWeek(context),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _selectedPeriod == 'week' ? (lang == 'vi' ? 'Tuần này' : 'This Week') : _selectedPeriod,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  // Summary Hero Card
                  _buildHeroCard(vm, t),
                  const SizedBox(height: 24),
  
                  // Chart Section
                  Text(t('performance_analysis'), 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildAdvancedChart(vm, lang),
                  
                  const SizedBox(height: 24),
                  
                  // Distribution Row
                  Row(children: [
                    Expanded(child: _StatusDistributionCard(label: t('late'), value: vm.lateDays.toString(), color: AppColors.error, icon: Icons.timer_off_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatusDistributionCard(label: t('remaining_leave'), value: '${vm.remainingLeave}', color: AppColors.success, icon: Icons.event_available_rounded)),
                  ]),
                  
                  const SizedBox(height: 24),
  
                  // Recent Logs Header
                  Row(children: [
                    Text(t('recent_history'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.5)),
                  ]),
                  const SizedBox(height: 8),
                  
                  // History List
                  ...vm.attendanceHistory.map((att) => _buildHistoryItem(att, t)),
                  
                  const SizedBox(height: 100),
                ])),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildHeroCard(StatisticsViewModel vm, String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('total_work_hours'), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('${vm.totalHours}h', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(label: t('normal_hours'), value: '${vm.totalHours - vm.totalOTHours}h'),
              _HeroStat(label: t('ot_hours'), value: '${vm.totalOTHours}h'),
              _HeroStat(label: t('rank'), value: 'A+'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedChart(StatisticsViewModel vm, String lang) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = vm.weeklyDataMap[groupIndex];
                String text = '';
                if (d['ot']! > 0) text = 'OT: ${d['ot']}h\n';
                text += 'Work: ${d['normal']! + d['deficiency']!}h';
                return BarTooltipItem(
                  text,
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                reservedSize: 28,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final daysVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  final daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final days = lang == 'vi' ? daysVi : daysEn;
                  int idx = v.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[idx], style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          barGroups: List.generate(7, (i) {
            final d = vm.weeklyDataMap[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d['normal']! + d['ot']! + d['deficiency']!,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  rodStackItems: [
                    if (d['deficiency']! > 0)
                      BarChartRodStackItem(0, d['deficiency']!, const Color(0xFFFBBF24)), // Yellow
                    if (d['normal']! > 0)
                      BarChartRodStackItem(0, d['normal']!, const Color(0xFF10B981)), // Green
                    if (d['ot']! > 0)
                      BarChartRodStackItem(d['normal']!, d['normal']! + d['ot']!, const Color(0xFFEF4444)), // Red
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(AttendanceModel att, String Function(String) t) {
    final duration = att.checkOut != null ? att.checkOut!.difference(att.checkIn!).inMinutes / 60.0 : 0.0;
    final normal = duration > 8 ? 8.0 : duration;
    final ot = duration > 8 ? duration - 8.0 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.event_note_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppDateUtils.formatDate(att.date), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text('${AppDateUtils.formatTime(att.checkIn!)} - ${att.checkOut != null ? AppDateUtils.formatTime(att.checkOut!) : t('working')}', 
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${normal.toStringAsFixed(1)}h', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF10B981))),
              if (ot > 0)
                Text('+${ot.toStringAsFixed(1)}h OT', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusDistributionCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatusDistributionCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String Function(String) t;
  const _StatusBadge({required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.success;
    String label = t('on_time');
    if (status == 'late') { color = AppColors.warning; label = t('late'); }
    if (status == 'absent') { color = AppColors.error; label = t('absent'); }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
