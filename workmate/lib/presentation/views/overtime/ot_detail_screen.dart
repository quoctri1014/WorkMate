import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';

class OTDetailScreen extends StatelessWidget {
  final OvertimeModel ot;
  const OTDetailScreen({super.key, required this.ot});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    Color statusBg;
    IconData statusIcon;

    switch (ot.status) {
      case 'approved':
        statusColor = const Color(0xFF059669);
        statusBg = const Color(0xFFECFDF5);
        statusText = 'ĐÃ DUYỆT';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEF2F2);
        statusText = 'TỪ CHỐI';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFFFBEB);
        statusText = 'CHỜ DUYỆT';
        statusIcon = Icons.pending_rounded;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết đăng ký OT',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B), size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Main Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: const Border(left: BorderSide(color: Color(0xFF075985), width: 8)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(statusText, style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                      ),
                      Text('#OT-${ot.id.toString().padLeft(8, '0')}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Chi tiết OT', style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text(
                    'Yêu cầu làm thêm giờ cho nội dung công việc: ${ot.workContent}',
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _DetailItem(icon: Icons.calendar_today_rounded, label: 'NGÀY ĐĂNG KÝ', value: AppDateUtils.formatDate(ot.date)),
                      const SizedBox(width: 16),
                      _DetailItem(icon: Icons.access_time_rounded, label: 'TỔNG GIỜ', value: '${ot.expectedHours}h'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Badge Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFBAE6FD),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                    child: Icon(statusIcon, color: const Color(0xFF0369A1), size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Trạng thái Phê duyệt', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0369A1))),
                  const SizedBox(height: 8),
                  Text(
                    ot.status == 'approved' ? 'Yêu cầu đã được xác nhận bởi quản lý trực tiếp.' : 'Yêu cầu đang chờ quản lý trực tiếp xác nhận.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w600, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075985),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Xem chứng từ', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Card
            _SectionCard(
              title: 'NỘI DUNG CÔNG VIỆC',
              icon: Icons.description_rounded,
              children: [
                const Text('MÔ TẢ CHI TIẾT', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text(
                  ot.workContent.isEmpty ? 'Không có mô tả chi tiết' : ot.workContent,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600, height: 1.6),
                ),
                const SizedBox(height: 20),
                const Text('DỰ ÁN', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 16, color: Color(0xFF0369A1)),
                    const SizedBox(width: 8),
                    const Text('Dự án WorkMate', style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0369A1))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
                Text(value, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 12, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155))),
      ],
    );
  }
}
