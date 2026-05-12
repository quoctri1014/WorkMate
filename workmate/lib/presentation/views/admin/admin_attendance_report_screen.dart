import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';

class AdminAttendanceReportScreen extends StatelessWidget {
  const AdminAttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text('Báo cáo chấm công', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 15,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: ListTile(
            title: Text('Nhân viên ${i+1}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            subtitle: Text('Vào: 08:05 • Ra: 17:10', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.1) : AppColors.successLight, 
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Text('Đúng giờ', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
