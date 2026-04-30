import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/repositories/mock_data.dart';
import 'admin_leave_approval_screen.dart';
import 'admin_employee_list_screen.dart';
import 'admin_attendance_report_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // Overview Cards
              Row(children: [
                Expanded(child: _QuickStat(label: 'Nhân viên', value: '124', icon: Icons.people_rounded, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _QuickStat(label: 'Đang online', value: '82', icon: Icons.online_prediction_rounded, color: AppColors.success)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _QuickStat(label: 'Chờ duyệt', value: '15', icon: Icons.pending_actions_rounded, color: AppColors.warning)),
                const SizedBox(width: 12),
                Expanded(child: _QuickStat(label: 'Vắng mặt', value: '3', icon: Icons.person_off_rounded, color: AppColors.error)),
              ]),
              const SizedBox(height: 24),

              // Attendance Chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tỷ lệ chuyên cần tuần này', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [const FlSpot(0, 3), const FlSpot(1, 4), const FlSpot(2, 3.5), const FlSpot(3, 5), const FlSpot(4, 4.5)],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Admin Menu
              const Text('QUẢN TRỊ HỆ THỐNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 12),
              _AdminMenuTile(
                icon: Icons.badge_rounded, color: AppColors.primary, title: 'Quản lý nhân sự', subtitle: 'Danh sách, hợp đồng, hồ sơ',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEmployeeListScreen())),
              ),
              _AdminMenuTile(
                icon: Icons.fact_check_rounded, color: AppColors.success, title: 'Phê duyệt yêu cầu', subtitle: 'Nghỉ phép, OT, bổ sung công',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLeaveApprovalScreen())),
              ),
              _AdminMenuTile(
                icon: Icons.analytics_rounded, color: AppColors.info, title: 'Báo cáo chấm công', subtitle: 'Thống kê đi muộn, về sớm',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAttendanceReportScreen())),
              ),
              _AdminMenuTile(
                icon: Icons.campaign_rounded, color: AppColors.warning, title: 'Gửi thông báo', subtitle: 'Thông báo toàn công ty',
                onTap: () {},
              ),
              const SizedBox(height: 40),
            ])),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _AdminMenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AdminMenuTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    ),
  );
}
