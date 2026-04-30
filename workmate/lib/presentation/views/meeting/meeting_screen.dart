import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/repositories/mock_data.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingViewModel>().fetchMeetings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final meetingVM = context.watch<MeetingViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);

    // Lọc cuộc họp theo ngày đã chọn
    final filteredMeetings = meetingVM.meetings.where((m) => 
      m.startTime.year == _selectedDate.year &&
      m.startTime.month == _selectedDate.month &&
      m.startTime.day == _selectedDate.day
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1C6185)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('meeting_title'),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: Color(0xFF1C6185),
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              '${lang == 'vi' ? 'Hôm nay' : 'Today'}, ${_selectedDate.day} ${lang == 'vi' ? 'Th${_selectedDate.month}' : 'May'}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Horizontal Date Selector
          _buildDateSelector(),

          const SizedBox(height: 24),

          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t('today_schedule'),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D3142),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    t('view_all'),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C6185),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meeting List
          Expanded(
            child: meetingVM.isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1C6185)))
              : filteredMeetings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C6185).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.event_note_rounded, size: 64, color: const Color(0xFF1C6185).withOpacity(0.2)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          lang == 'vi' ? 'Không có lịch họp nào' : 'No meetings scheduled',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.grey[400], 
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredMeetings.length,
                    itemBuilder: (context, index) => _MeetingCard(
                      meeting: filteredMeetings[index],
                      t: t,
                      lang: lang,
                      deptNames: filteredMeetings[index].departmentIds.map((id) => meetingVM.getDeptName(id)).toList(),
                      onRemind: () {
                        meetingVM.scheduleReminder(filteredMeetings[index]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(lang == 'vi' ? '✅ Đã đặt nhắc nhở trước 5 phút!' : '✅ Reminder set for 5 mins before!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: const Color(0xFF1C6185),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 14, 
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 2));
          final isSelected = date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1C6185) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected 
                  ? [BoxShadow(color: const Color(0xFF1C6185).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getShortWeekday(date.weekday).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF9EA5B1),
                    ),
                  ),
                  if (isSelected) 
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5, height: 5,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getShortWeekday(int day) {
    const map = {1: 'T2', 2: 'T3', 3: 'T4', 4: 'T5', 5: 'T6', 6: 'T7', 7: 'CN'};
    return map[day] ?? '';
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final String Function(String) t;
  final String lang;
  final List<String> deptNames;
  final VoidCallback onRemind;

  const _MeetingCard({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
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
                  const Color(0xFFE3F2FD),
                  const Color(0xFF1E88E5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        meeting.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                        size: 18,
                        color: const Color(0xFF1C6185),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          meeting.isOnline ? 'Google Meet' : meeting.location,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C6185),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded, color: Color(0xFFBDBDBD)),
              ],
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              meeting.title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D3142),
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
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF9EA5B1),
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
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF64748B),
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
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1C6185),
                      ),
                    ),
                    Text(
                      lang == 'vi' ? 'THỜI GIAN' : 'TIME',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFBDBDBD),
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
                  backgroundColor: const Color(0xFF1C6185),
                  elevation: 8,
                  shadowColor: const Color(0xFF1C6185).withOpacity(0.3),
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
