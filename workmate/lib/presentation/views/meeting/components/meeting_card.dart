import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/core/constants/app_colors.dart';

class MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final String Function(String) t;
  final String lang;
  final List<String> deptNames;
  final VoidCallback onRemind;

  const MeetingCard({
    super.key,
    required this.meeting, 
    required this.t, 
    required this.lang,
    required this.deptNames,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(35),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
          BoxShadow(
            color: const Color(0xFF1C6185).withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badges
            Row(
              children: [
                _buildBadge(
                  lang == 'vi' ? 'SẮP DIỄN RA' : 'UPCOMING',
                  Theme.of(context).brightness == Brightness.dark ? Colors.blue.withOpacity(0.15) : const Color(0xFFE3F2FD),
                  Theme.of(context).brightness == Brightness.dark ? Colors.blue[300]! : const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        meeting.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                        size: 18,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[200] : const Color(0xFF1C6185),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            if (meeting.isOnline) {
                              final url = meeting.location.startsWith('http') 
                                ? meeting.location 
                                : 'https://${meeting.location}';
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          child: Text(
                            meeting.isOnline ? 'Google Meet (Nhấn để tham gia)' : meeting.location,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : const Color(0xFF1C6185),
                              decoration: meeting.isOnline ? TextDecoration.underline : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                Icon(Icons.more_horiz_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
              ],
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              meeting.title,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 18),

            // Departments & Time
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Departments List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == 'vi' ? 'PHÒNG BAN THAM GIA' : 'DEPARTMENTS',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: deptNames.map((name) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${AppDateUtils.formatTime(meeting.startTime)} - ${AppDateUtils.formatTime(meeting.endTime)}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : const Color(0xFF1C6185),
                      ),
                    ),
                    Text(
                      lang == 'vi' ? 'THỜI GIAN' : 'TIME',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onRemind,
                icon: const Icon(Icons.notifications_active_outlined, size: 22, color: Colors.white),
                label: Text(
                  t('remind_me'),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 8,
                  shadowColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : AppColors.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}
