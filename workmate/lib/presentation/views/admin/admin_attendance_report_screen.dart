import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';

class AdminAttendanceReportScreen extends StatelessWidget {
  const AdminAttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Báo cáo chấm công')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 15,
        itemBuilder: (context, i) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Nhân viên ${i+1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Vào: 08:05 • Ra: 17:10'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
              child: const Text('Đúng giờ', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
