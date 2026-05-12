import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'package:workmate/presentation/views/meeting/components/meeting_card.dart';

class AllMeetingsScreen extends StatelessWidget {
  const AllMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final meetingVM = context.watch<MeetingViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);

    // Group meetings by month manually
    final groupedMeetings = <String, List<MeetingModel>>{};
    for (var m in meetingVM.meetings) {
      final key = AppDateUtils.formatMonthYear(m.startTime, lang);
      groupedMeetings.putIfAbsent(key, () => []).add(m);
    }

    // Sort months descending (Newest first)
    final sortedMonths = groupedMeetings.keys.toList()..sort((a, b) {
      // Parse back to compare or just use meetings inside
      final dateA = groupedMeetings[a]!.first.startTime;
      final dateB = groupedMeetings[b]!.first.startTime;
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lang == 'vi' ? 'Toàn bộ lịch họp' : 'All Meetings',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
      ),
      body: meetingVM.isLoading 
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : meetingVM.meetings.isEmpty
            ? _buildEmptyState(context, lang)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: sortedMonths.length,
                itemBuilder: (context, index) {
                  final month = sortedMonths[index];
                  final meetings = groupedMeetings[month]!;
                  
                  // Sort meetings within month (Newest first or Oldest first? Usually Newest for "All")
                  meetings.sort((a, b) => b.startTime.compareTo(a.startTime));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 16, top: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              month.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...meetings.map((m) => MeetingCard(
                        meeting: m,
                        t: t,
                        lang: lang,
                        deptNames: m.departmentIds.map((id) => meetingVM.getDeptName(id)).toList(),
                        onRemind: () {
                          meetingVM.scheduleReminder(m);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(lang == 'vi' ? '✅ Đã đặt nhắc nhở!' : '✅ Reminder set!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey[900] : const Color(0xFF1C6185),
                            ),
                          );
                        },
                      )),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFF1C6185).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFF1C6185).withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          Text(
            lang == 'vi' ? 'Chưa có dữ liệu lịch họp' : 'No meeting history found',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: Colors.grey[400], 
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
