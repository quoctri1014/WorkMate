import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'package:workmate/presentation/views/leave/leave_detail_screen.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  String _activeTab = 'all'; // all, approved, pending, rejected

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<HomeViewModel>().user;
      if (user != null) {
        context.read<LeaveViewModel>().fetchLeaves(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final leaveVM = context.watch<LeaveViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);
    
    final filteredLeaves = leaveVM.leaves.where((l) {
      if (_activeTab == 'all') return true;
      return l.status == _activeTab;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(t('leave_history'), style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Statistics Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _StatCard(label: 'CÒN LẠI', value: '${leaveVM.remainingLeave} ngày', color: const Color(0xFF0369A1)),
                const SizedBox(width: 16),
                _StatCard(label: 'ĐANG CHỜ', value: '${leaveVM.leaves.where((l) => l.status == 'pending').length} đơn', color: const Color(0xFFF59E0B)),
              ],
            ),
          ),

          // Tabs
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _TabItem(label: 'Tất cả', isActive: _activeTab == 'all', onTap: () => setState(() => _activeTab = 'all')),
                _TabItem(label: 'Đã duyệt', isActive: _activeTab == 'approved', onTap: () => setState(() => _activeTab = 'approved')),
                _TabItem(label: 'Đang chờ', isActive: _activeTab == 'pending', onTap: () => setState(() => _activeTab = 'pending')),
              ],
            ),
          ),

          // List
          Expanded(
            child: leaveVM.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filteredLeaves.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredLeaves.length,
                    itemBuilder: (context, index) => _buildLeaveItem(filteredLeaves[index], t),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Không tìm thấy dữ liệu', style: TextStyle(fontFamily: 'Nunito', color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildLeaveItem(LeaveModel leave, String Function(String) t) {
    Color statusColor;
    String statusText;
    switch (leave.status) {
      case 'approved': statusColor = const Color(0xFF10B981); statusText = 'ĐÃ DUYỆT'; break;
      case 'rejected': statusColor = const Color(0xFFEF4444); statusText = 'TỪ CHỐI'; break;
      default: statusColor = const Color(0xFFF59E0B); statusText = 'CHỜ DUYỆT';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF0369A1), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave.leaveType, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))),
                    Text('${leave.totalDays} ngày nghỉ', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              _buildDateInfo('Từ ngày', AppDateUtils.formatDate(leave.fromDate)),
              const Spacer(),
              _buildDateInfo('Đến ngày', AppDateUtils.formatDate(leave.toDate)),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showDetail(leave),
                child: const Text('Chi tiết >', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0369A1))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w700)),
        Text(date, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
      ],
    );
  }

  void _showDetail(LeaveModel leave) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeaveDetailScreen(leave: leave)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _TabItem({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : []),
          child: Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: isActive ? const Color(0xFF1E293B) : const Color(0xFF64748B))),
        ),
      ),
    );
  }
}
