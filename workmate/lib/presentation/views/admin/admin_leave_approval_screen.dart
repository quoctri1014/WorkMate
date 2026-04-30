import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/data/repositories/mock_data.dart';
import 'package:workmate/data/models/models.dart';

class AdminLeaveApprovalScreen extends StatefulWidget {
  const AdminLeaveApprovalScreen({super.key});

  @override
  State<AdminLeaveApprovalScreen> createState() => _AdminLeaveApprovalScreenState();
}

class _AdminLeaveApprovalScreenState extends State<AdminLeaveApprovalScreen> {
  final List<LeaveModel> _pendingLeaves = [
    LeaveModel(id: 'l1', userId: 'u1', userName: 'Nguyễn Văn A', leaveType: 'annual', fromDate: DateTime.now().add(const Duration(days: 2)), toDate: DateTime.now().add(const Duration(days: 3)), reason: 'Nghỉ du lịch gia đình', status: 'pending', createdAt: DateTime.now()),
    LeaveModel(id: 'l2', userId: 'u2', userName: 'Trần Thị B', leaveType: 'sick', fromDate: DateTime.now().add(const Duration(days: 1)), toDate: DateTime.now().add(const Duration(days: 1)), reason: 'Sốt xuất huyết', status: 'pending', createdAt: DateTime.now().subtract(const Duration(hours: 5))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Duyệt đơn nghỉ phép')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _pendingLeaves.length,
        itemBuilder: (context, i) {
          final leave = _pendingLeaves[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(backgroundColor: AppColors.primarySurface, child: Text(leave.userId[1])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nguyễn Văn A', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(leave.leaveTypeLabel, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ])),
                Text(leave.statusLabel, style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11)),
              ]),
              const Divider(height: 24),
              Text('Lý do: ${leave.reason}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Text('Thời gian: ${leave.totalDays} ngày', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Từ chối'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Duyệt đơn'))),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
