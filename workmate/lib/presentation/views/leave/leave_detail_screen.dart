import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';

class LeaveDetailScreen extends StatelessWidget {
  final LeaveModel leave;

  const LeaveDetailScreen({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (leave.status) {
      case 'approved': statusColor = const Color(0xFF10B981); statusText = 'ĐÃ DUYỆT'; break;
      case 'rejected': statusColor = const Color(0xFFEF4444); statusText = 'TỪ CHỐI'; break;
      default: statusColor = const Color(0xFFF59E0B); statusText = 'CHỜ DUYỆT';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Chi tiết nghỉ phép', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    leave.leaveType,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${leave.totalDays} ngày nghỉ',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('THÔNG TIN CHI TIẾT', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.description_outlined, 'Lý do', leave.reason),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Thời gian nghỉ', '${AppDateUtils.formatDate(leave.fromDate)} - ${AppDateUtils.formatDate(leave.toDate)}'),
                  if (leave.attachments.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                    _buildAttachments(leave.attachments),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Decorative banner like in image 5
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: const DecorationImage(
                  image: NetworkImage('https://img.freepik.com/free-vector/summer-vacation-concept-with-palm-leaves_23-2148529452.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vacation Time!', style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Tận hưởng kỳ nghỉ của bạn thật trọn vẹn.', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF0369A1), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500])),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments(List<String> urls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.image_outlined, color: Color(0xFF0369A1), size: 20),
            ),
            const SizedBox(width: 16),
            Text('Minh chứng', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            itemBuilder: (context, i) => Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(urls[i].startsWith('http') ? urls[i] : 'http://10.0.2.2:5000${urls[i]}'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
