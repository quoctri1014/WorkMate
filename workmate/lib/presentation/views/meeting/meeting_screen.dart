import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/data/repositories/mock_data.dart';
import 'package:workmate/data/models/models.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'package:workmate/presentation/views/meeting/all_meetings_screen.dart';
import 'package:workmate/presentation/views/meeting/components/meeting_card.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeetingViewModel>().fetchMeetings();
      _scrollToSelectedDate();
    });
  }

  void _scrollToSelectedDate() {
    if (_scrollController.hasClients) {
      // Mỗi item width 70 + 16 (margin horizontal 8*2) = 86
      // Căn giữa ngày đã chọn: offset = (index * 86) - (screenWidth / 2) + (itemWidth / 2)
      final index = _selectedDate.day - 1;
      final screenWidth = MediaQuery.of(context).size.width;
      double offset = (index * 86.0) - (screenWidth / 2) + 43.0;
      
      // Giới hạn offset không âm và không vượt quá maxScrollExtent
      if (offset < 0) offset = 0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (offset > maxScroll) offset = maxScroll;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
      );
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'CHỌN THÁNG',
    );
    if (picked != null) {
      setState(() {
        _focusedMonth = DateTime(picked.year, picked.month, 1);
        _selectedDate = DateTime(picked.year, picked.month, 
            _selectedDate.month == picked.month ? _selectedDate.day : 1);
      });
      // Đợi UI render xong rồi scroll
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final meetingVM = context.watch<MeetingViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);
    
    final bool isSelectedToday = AppDateUtils.isToday(_selectedDate);

    // Lọc cuộc họp theo ngày đã chọn
    final filteredMeetings = meetingVM.meetings.where((m) => 
      m.startTime.year == _selectedDate.year &&
      m.startTime.month == _selectedDate.month &&
      m.startTime.day == _selectedDate.day
    ).toList();

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
          t('meeting_title'),
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _selectMonth,
            icon: Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Date & Month Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isSelectedToday ? (lang == 'vi' ? 'Hôm nay' : 'Today') + ', ' : ''}${_selectedDate.day} ${lang == 'vi' ? 'Th${_selectedDate.month}' : AppDateUtils.formatMonthYear(_selectedDate, 'en').split(' ')[0]}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                GestureDetector(
                  onTap: _selectMonth,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFF1C6185).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF1C6185),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF1C6185)),
                      ],
                    ),
                  ),
                ),
              ],
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
                  isSelectedToday ? t('today_schedule') : (lang == 'vi' ? 'Lịch ngày ${_selectedDate.day} Th${_selectedDate.month}' : 'Schedule for ${_selectedDate.day}'),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllMeetingsScreen()),
                    );
                  },
                  child: Text(
                    t('view_all'),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meeting List
          Expanded(
            child: meetingVM.isLoading 
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
              : filteredMeetings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1C6185)).withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.event_note_rounded, size: 64, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1C6185)).withOpacity(0.2)),
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
                    itemBuilder: (context, index) => MeetingCard(
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
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey[900] : const Color(0xFF1C6185),
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
    final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: daysInMonth, 
        itemBuilder: (context, index) {
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, index + 1);
          final isSelected = AppDateUtils.isSameDay(date, _selectedDate);
          final isToday = AppDateUtils.isToday(date);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected 
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
                  : (Theme.of(context).brightness == Brightness.dark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
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
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _getShortWeekday(date.weekday).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8) : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                  ),
                  if (isToday) 
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary, 
                        shape: BoxShape.circle
                      ),
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
