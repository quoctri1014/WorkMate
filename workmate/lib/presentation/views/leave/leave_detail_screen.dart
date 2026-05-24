import 'package:flutter/material.dart';
import \'package:easy_localization/easy_localization.dart\';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/data/repositories/api_service.dart';

class LeaveDetailScreen extends StatelessWidget {
  final LeaveModel leave;

  const LeaveDetailScreen({super.key, required this.leave});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (leave.status) {
      case 'approved': statusColor = const Color(0xFF10B981); statusText = tr('approved').toUpperCase(); break;
      case 'rejected': statusColor = const Color(0xFFEF4444); statusText = 'TỪ CHỐI'; break;
      default: statusColor = const Color(0xFFF59E0B); statusText = 'CHỜ DUYỆT';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(tr('leave_details'), style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
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
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${leave.totalDays} ngày nghỉ',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(tr('detailed_information'), style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7), letterSpacing: 1)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, Icons.description_outlined, 'Lý do', leave.reason),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.05))),
                  _buildDetailRow(context, Icons.calendar_today_outlined, 'Thời gian nghỉ', '${AppDateUtils.formatDate(leave.fromDate)} - ${AppDateUtils.formatDate(leave.toDate)}'),
                  if (leave.attachments.isNotEmpty) ...[
                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.05))),
                    _buildAttachments(context, leave.attachments),
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

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF0369A1), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6))),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context, List<String> urls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.image_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF0369A1), size: 20),
            ),
            const SizedBox(width: 16),
            Text('Minh chứng', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6))),
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
                  image: NetworkImage(urls[i].startsWith('http') ? urls[i] : '${ApiService.baseHost}${urls[i]}'),
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
