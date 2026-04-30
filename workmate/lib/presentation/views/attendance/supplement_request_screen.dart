import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class SupplementRequestScreen extends StatefulWidget {
  const SupplementRequestScreen({super.key});

  @override
  State<SupplementRequestScreen> createState() => _SupplementRequestScreenState();
}

class _SupplementRequestScreenState extends State<SupplementRequestScreen> {
  DateTime _selectedDate = DateTime.now();
  final _reasonCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do bổ sung công')));
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2)); // Mock API call
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yêu cầu đã được gửi tới HR'), backgroundColor: AppColors.success));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yêu cầu bổ sung công'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, color: AppColors.info),
                SizedBox(width: 10),
                Expanded(child: Text('Sử dụng khi bạn quên chấm công hoặc có sai sót về giờ làm.', style: TextStyle(fontSize: 12, color: AppColors.info))),
              ]),
            ),
            const SizedBox(height: 24),
            const Text('NGÀY CẦN BỔ SUNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(AppDateUtils.formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            const Text('LÝ DO CHI TIẾT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Giải trình lý do quên chấm công...',
                contentPadding: EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Gửi yêu cầu bổ sung'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
