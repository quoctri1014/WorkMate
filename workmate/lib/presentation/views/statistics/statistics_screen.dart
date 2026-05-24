import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

import 'package:workmate/data/models/models.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int touchedIndex = -1;
  String _selectedPeriod = 'month';

  DateTime _currentMonth = DateTime.now();
  int _selectedWeekIndex = 0;
  List<List<DateTime>> _weeks = [];

  List<List<DateTime>> _getWeeksOfMonth(DateTime month) {
    List<List<DateTime>> weeks = [];
    DateTime firstDay = DateTime(month.year, month.month, 1);
    DateTime lastDay = DateTime(month.year, month.month + 1, 0);

    DateTime current = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    while (current.isBefore(lastDay) || current.isAtSameMomentAs(lastDay)) {
      List<DateTime> week = [];
      for (int i = 0; i < 7; i++) {
        week.add(current.add(Duration(days: i)));
      }
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }
    return weeks;
  }

  void _setDefaultWeek() {
    _weeks = _getWeeksOfMonth(_currentMonth);
    final now = DateTime.now();
    _selectedWeekIndex = 0;
    for (int i = 0; i < _weeks.length; i++) {
      if (_weeks[i].any((d) => d.year == now.year && d.month == now.month && d.day == now.day)) {
        _selectedWeekIndex = i;
        break;
      }
    }
  }

  List<Map<String, double>> _getChartData(StatisticsViewModel vm, List<DateTime> currentWeek) {
    List<Map<String, double>> res = List.generate(7, (_) => {'normal': 0.0, 'ot': 0.0, 'deficiency': 0.0});
    
    for (var att in vm.attendanceHistory) {
      int dayIdx = att.date.weekday - 1; 
      if (currentWeek.any((d) => d.year == att.date.year && d.month == att.date.month && d.day == att.date.day)) {
        res[dayIdx]['normal'] = (res[dayIdx]['normal'] ?? 0) + att.displayNormalHours;
        res[dayIdx]['ot'] = (res[dayIdx]['ot'] ?? 0) + att.otHours;
      }
    }
    return res;
  }

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _setDefaultWeek();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeVM = context.read<HomeViewModel>();
      if (homeVM.user != null) {
        context.read<StatisticsViewModel>().fetchStatistics(homeVM.user!.id, period: _selectedPeriod);
      }
    });
  }

  void _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'CHỌN THÁNG THỐNG KÊ',
    );

    if (picked != null) {
      final DateTime firstDay = DateTime(picked.year, picked.month, 1);
      final DateTime lastDay = DateTime(picked.year, picked.month + 1, 0);

      final homeVM = context.read<HomeViewModel>();
      if (homeVM.user != null) {
        context.read<StatisticsViewModel>().fetchStatistics(
          homeVM.user!.id, 
          startDate: firstDay, 
          endDate: lastDay
        );
      }
      
      final profileVM = context.read<ProfileViewModel>();
      final lang = profileVM.selectedLanguage;
      setState(() {
        _currentMonth = picked;
        _setDefaultWeek();
        _selectedPeriod = lang == 'vi' 
            ? 'Tháng ${picked.month}/${picked.year}' 
            : 'Month ${picked.month}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();
    final profileVM = context.watch<ProfileViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => key.tr();
    
    return Scaffold(
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
                floating: true,
                pinned: true,
                elevation: 0,
                centerTitle: false,
                title: Text(t('attendance_analysis'), 
                  style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 22)),
                actions: [
                  GestureDetector(
                    onTap: () => _selectMonth(context),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.calendar_month_rounded, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          _selectedPeriod == 'month' ? (lang == 'vi' ? 'Tháng này' : 'This Month') : _selectedPeriod,
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('performance_analysis'), 
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7), letterSpacing: 1.5)),
                      if (_weeks.isNotEmpty)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.primary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _selectedWeekIndex > 0 ? () => setState(() => _selectedWeekIndex--) : null,
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(lang == 'vi' ? 'Tuần ${_selectedWeekIndex + 1}' : 'Week ${_selectedWeekIndex + 1}', 
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                Text(
                                  '${_weeks[_selectedWeekIndex].first.day}/${_weeks[_selectedWeekIndex].first.month} - ${_weeks[_selectedWeekIndex].last.day}/${_weeks[_selectedWeekIndex].last.month}',
                                  style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8))
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _selectedWeekIndex < _weeks.length - 1 ? () => setState(() => _selectedWeekIndex++) : null,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final currentWeek = _weeks.isNotEmpty ? _weeks[_selectedWeekIndex] : <DateTime>[];
                      final chartData = _getChartData(vm, currentWeek);
                      return _buildAdvancedChart(chartData, lang, currentWeek);
                    }
                  ),
                  
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
                    Text(t('recent_history'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7), letterSpacing: 1.5)),
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
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
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

  Widget _buildAdvancedChart(List<Map<String, double>> chartData, String lang, List<DateTime> currentWeek) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppColors.cardShadow,
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey[800]! : AppColors.textPrimary,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = chartData[groupIndex];
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
                getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 10)),
                reservedSize: 28,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) {
                  final daysVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                  final daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final days = lang == 'vi' ? daysVi : daysEn;
                  int idx = v.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox();
                  
                  String dateStr = '';
                  if (currentWeek.isNotEmpty && idx < currentWeek.length) {
                    dateStr = '\n${currentWeek[idx].day}/${currentWeek[idx].month}';
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[idx] + dateStr, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Theme.of(context).dividerColor.withOpacity(0.1), strokeWidth: 1),
          ),
          barGroups: List.generate(7, (i) {
            final d = chartData[i];
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
    final normal = att.displayNormalHours;
    final ot = att.otHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : AppColors.primarySurface, borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.event_note_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppDateUtils.formatDate(att.date), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time_rounded, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text('${att.checkIn != null ? AppDateUtils.formatTime(att.checkIn!) : '--:--'} - ${att.checkOut != null ? AppDateUtils.formatTime(att.checkOut!) : t('working')}', 
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${normal.toStringAsFixed(1)}h', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.green[300] : const Color(0xFF10B981))),
              if (ot > 0)
                Text('+${ot.toStringAsFixed(1)}h OT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.red[300] : const Color(0xFFEF4444))),
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
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20), boxShadow: Theme.of(context).brightness == Brightness.dark ? null : AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
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
