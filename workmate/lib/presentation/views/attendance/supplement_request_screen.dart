import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/utils/date_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/data/repositories/api_service.dart';

class SupplementRequestScreen extends StatefulWidget {
  const SupplementRequestScreen({super.key});

  @override
  State<SupplementRequestScreen> createState() => _SupplementRequestScreenState();
}

class _SupplementRequestScreenState extends State<SupplementRequestScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _checkInTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 17, minute: 30);
  final _reasonCtrl = TextEditingController();
  bool _isLoadingCount = true;
  bool _isSubmitting = false;
  int _forgotCount = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadForgotCount();
  }

  Future<void> _loadForgotCount() async {
    setState(() => _isLoadingCount = true);
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      final now = DateTime.now();
      final month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      print('📡 Debug: Checking limit for User ${user.id} in Month $month');
      final count = await _apiService.checkForgotLimit(user.id, month);
      print('📡 Debug: Current count is $count');
      if (mounted) {
        setState(() {
          _forgotCount = count;
          _isLoadingCount = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Theme.of(ctx).cardColor,
            onSurface: Theme.of(ctx).colorScheme.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _checkOutTime,
    );
    if (t != null) {
      setState(() {
        if (isCheckIn) _checkInTime = t;
        else _checkOutTime = t;
      });
    }
  }

  Future<void> _submit() async {
    if (_forgotCount >= 5) {
      _showSnackBar('Bạn đã hết lượt bổ sung trong tháng này', AppColors.error);
      return;
    }

    if (_reasonCtrl.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập lý do bổ sung công', AppColors.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;

    final fromDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _checkInTime.hour, _checkInTime.minute);
    final toDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _checkOutTime.hour, _checkOutTime.minute);

    final success = await _apiService.submitApproval({
      'employee_id': user.id,
      'employee_name': user.name,
      'type': 'Quên chấm công',
      'reason': _reasonCtrl.text.trim(),
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'status': 'pending'
    });

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _showSnackBar('Yêu cầu đã được gửi tới quản trị viên', AppColors.success);
        Navigator.pop(context);
      } else {
        _showSnackBar('Gửi yêu cầu thất bại. Vui lòng thử lại.', AppColors.error);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isLimitReached = _forgotCount >= 5;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Bổ sung chấm công', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Limit Card
            _buildLimitCard(isLimitReached),
            
            const SizedBox(height: 32),
            _buildSectionTitle('THÔNG TIN CHẤM CÔNG'),
            const SizedBox(height: 12),
            
            // Date Selection
            _buildInputContainer(
              label: 'Ngày cần bổ sung',
              icon: Icons.calendar_today_rounded,
              value: AppDateUtils.formatDate(_selectedDate),
              onTap: _pickDate,
            ),
            
            const SizedBox(height: 16),
            
            // Time Selection Row
            Row(
              children: [
                Expanded(
                  child: _buildInputContainer(
                    label: 'Giờ vào',
                    icon: Icons.login_rounded,
                    iconColor: AppColors.success,
                    value: _checkInTime.format(context),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputContainer(
                    label: 'Giờ ra',
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    value: _checkOutTime.format(context),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionTitle('detailed_reason'.tr()),
            const SizedBox(height: 12),
            
            // Reason Input
            TextField(
              controller: _reasonCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhập lý do cụ thể (VD: Quên mang thẻ, lỗi máy chấm công...)',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            
            const SizedBox(height: 40),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isSubmitting || isLimitReached || _isLoadingCount ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLimitReached ? Colors.grey.shade400 : AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      isLimitReached ? 'ĐÃ HẾT LƯỢT BỔ SUNG' : 'GỬI YÊU CẦU PHÊ DUYỆT',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white),
                    ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Yêu cầu sẽ được gửi tới Ban quản lý phê duyệt',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitCard(bool isLimitReached) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLimitReached ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF442726) : const Color(0xFFFFF1F2)) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLimitReached ? (Theme.of(context).brightness == Brightness.dark ? Colors.red.withOpacity(0.3) : const Color(0xFFFDA4AF)) : Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isLimitReached ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLimitReached ? Icons.warning_rounded : Icons.info_rounded,
                  color: isLimitReached ? Colors.red : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giới hạn bổ sung tháng này',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isLimitReached ? Colors.red : Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLimitReached 
                        ? 'Bạn đã sử dụng hết 5 lượt cho phép'
                        : 'Bạn đã sử dụng $_forgotCount trên tổng số 5 lượt',
                      style: TextStyle(fontSize: 11, color: isLimitReached ? (Theme.of(context).brightness == Brightness.dark ? Colors.redAccent : Colors.red.withOpacity(0.7)) : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                '$_forgotCount/5',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isLimitReached ? Colors.red : AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _forgotCount / 5,
              backgroundColor: isLimitReached ? Colors.red.withOpacity(0.1) : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(isLimitReached ? Colors.red : AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), letterSpacing: 1.2),
    );
  }

  Widget _buildInputContainer({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 12),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
