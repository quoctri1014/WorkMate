import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/i18n/app_translations.dart';
import 'ot_history_screen.dart';

class OTRequestScreen extends StatefulWidget {
  const OTRequestScreen({super.key});

  @override
  State<OTRequestScreen> createState() => _OTRequestScreenState();
}

class _OTRequestScreenState extends State<OTRequestScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  double _hours = 2.0;
  final _contentCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _submit(String Function(String) t) async {
    if (_contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('error_work_content')), backgroundColor: AppColors.error));
      return;
    }
    final vm = context.read<OvertimeViewModel>();
    final homeVM = context.read<HomeViewModel>();
    final user = homeVM.user;

    if (user != null) {
      final success = await vm.submitOTRequest(
        employeeId: user.id,
        employeeName: user.name,
        date: _date,
        hours: _hours,
        workContent: _contentCtrl.text,
      );
      if (success) {
        setState(() => _submitted = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi gửi đơn OT!'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileVM = context.watch<ProfileViewModel>();
    final lang = profileVM.selectedLanguage;
    String t(String key) => AppTranslations.getText(lang, key);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(t('ot_request_title'), style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
        actions: [
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OTHistoryScreen())),
            child: Text(t('history'), style: const TextStyle(fontFamily: 'Nunito', color: AppColors.primary, fontWeight: FontWeight.w600))),
        ],
      ),
      body: _submitted ? _buildSuccess(t) : _buildForm(t, lang),
    );
  }

  Widget _buildForm(String Function(String) t, String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.more_time_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OVERTIME REQUEST', style: TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1)),
                    Text(t('ot_form_subtitle'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                  ],
                )),
                const Icon(Icons.access_time_rounded, color: Colors.white54, size: 44),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _SectionLabel(t('ot_date_label')),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(AppDateUtils.formatDate(_date), style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          _SectionLabel(t('ot_hours_label')),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              const Icon(Icons.timer_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _hours,
                  items: [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0, 6.0].map((h) =>
                    DropdownMenuItem(value: h, child: Text('$h ${lang == 'vi' ? 'giờ' : 'hrs'}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 14)))).toList(),
                  onChanged: (v) => setState(() => _hours = v!),
                ),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          _SectionLabel(t('ot_content_label')),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: TextField(
              controller: _contentCtrl,
              maxLines: 4,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: t('ot_content_hint'),
                hintStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint),
                prefixIcon: const Padding(padding: EdgeInsets.only(left: 14, top: 12, right: 8), child: Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primary)),
                border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Consumer<OvertimeViewModel>(
            builder: (ctx, vm, _) => SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : () => _submit(t),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: vm.isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(t('ot_submit_btn'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSuccess(String Function(String) t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 88, height: 88,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text(t('ot_success_title'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(t('ot_success_msg'), textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text(t('back_home'), style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1,
  ));
}
