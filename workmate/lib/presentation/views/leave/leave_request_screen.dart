import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/core/services/upload_service.dart';
import 'dart:io';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  String _leaveType = 'Nghỉ phép năm';
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  bool _isHalfDay = false;
  final _reasonController = TextEditingController();
  List<String> _uploadedUrls = [];
  bool _isUploading = false;
  bool _isSuccess = false;

  final List<String> _types = ['Nghỉ phép năm', 'Nghỉ bệnh', 'Nghỉ việc riêng', 'Nghỉ không lương'];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final File? image = await UploadService.pickImage();
    if (image != null) {
      setState(() => _isUploading = true);
      final result = await UploadService.uploadImage(image);
      if (result.success && result.url != null) {
        setState(() => _uploadedUrls.add(result.url!));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải ảnh: ${result.error}')),
          );
        }
      }
      setState(() => _isUploading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _handleSubmit() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do nghỉ')));
      return;
    }

    if (_leaveType == 'Nghỉ bệnh' && _uploadedUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nghỉ bệnh cần có ảnh minh chứng')));
      return;
    }

    final vm = context.read<LeaveViewModel>();
    final homeVM = context.read<HomeViewModel>();
    final user = homeVM.user;

    if (user == null) return;

    final double remainingLeave = vm.remainingLeave;
    final double totalDays = _isHalfDay ? 0.5 : (_toDate.difference(_fromDate).inDays + 1).toDouble();
    if (_leaveType == 'Nghỉ phép năm' && totalDays > remainingLeave) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bạn chỉ còn $remainingLeave ngày phép năm. Vui lòng chọn lại.')));
      return;
    }

    final success = await vm.submitLeaveRequest(
      employeeId: user.id,
      employeeName: user.name,
      leaveType: _leaveType,
      fromDate: _fromDate,
      toDate: _toDate,
      reason: _reasonController.text,
      attachments: _uploadedUrls,
      isHalfDay: _isHalfDay,
    );

    if (success) {
      setState(() => _isSuccess = true);
    } else {
      if (mounted) {
        final errorMsg = vm.errorMessage ?? 'Gửi yêu cầu thất bại, vui lòng thử lại';
        if (vm.errorMessage != null) {
          _showErrorDialog(errorMsg);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
              ),
              const SizedBox(height: 20),
              const Text('Thông báo', style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF64748B), height: 1.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Đã hiểu', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessView();

    final leaveVM = context.watch<LeaveViewModel>();
    const double totalYearlyLeave = 12.0;
    double usedLeave = leaveVM.usedLeave;
    double remainingLeave = totalYearlyLeave - usedLeave;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tạo đơn báo nghỉ', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Yêu cầu nghỉ phép mới', style: TextStyle(fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1C6185))),
            const Text('Vui lòng điền đầy đủ thông tin bên dưới để gửi yêu cầu nghỉ phép của bạn.', style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 32),

            // Leave Balance Cards
            Row(
              children: [
                _BalanceCard(label: 'SỐ NGÀY PHÉP CÒN', value: remainingLeave.toString(), color: const Color(0xFF1C6185)),
                const SizedBox(width: 16),
                _BalanceCard(label: 'ĐÃ SỬ DỤNG', value: usedLeave.toString(), color: const Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 32),

            _buildLabel('LOẠI NGHỈ PHÉP'),
            _buildDropdown(remainingLeave),
            const SizedBox(height: 24),

            _buildLabel('TỪ NGÀY'),
            _buildDatePicker(true),
            const SizedBox(height: 24),

            _buildLabel('ĐẾN NGÀY'),
            _buildDatePicker(false),
            const SizedBox(height: 24),

            // Half day toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0).withOpacity(0.4), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 20, color: Color(0xFF1C6185)),
                  const SizedBox(width: 12),
                  const Text('Nghỉ nửa ngày', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const Spacer(),
                  Switch(value: _isHalfDay, onChanged: (val) => setState(() => _isHalfDay = val), activeColor: const Color(0xFF1C6185)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('LÝ DO NGHỈ'),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập lý do chi tiết của bạn tại đây...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 24),

            // Conditional Attachment Section
            if (_leaveType == 'Nghỉ bệnh') ...[
              _buildLabel('BẰNG CHỨNG (NẾU CÓ)'),
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      if (_isUploading)
                        const CircularProgressIndicator()
                      else if (_uploadedUrls.isNotEmpty)
                        const Icon(Icons.check_circle, color: Colors.green, size: 40)
                      else
                        const Icon(Icons.cloud_upload_outlined, color: Color(0xFF1C6185), size: 40),
                      const SizedBox(height: 12),
                      Text(_uploadedUrls.isNotEmpty ? 'Đã tải lên ${_uploadedUrls.length} tệp' : 'Tải ảnh hoặc tài liệu đính kèm', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 14)),
                      const Text('PNG, JPG, PDF tối đa 5MB', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9AD6FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: const Text('Gửi yêu cầu', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
    );
  }

  Widget _buildDropdown(double remainingLeave) {
    // Lọc danh sách loại nghỉ nếu hết phép năm
    List<String> availableTypes = List.from(_types);
    if (remainingLeave <= 0) {
      availableTypes.remove('Nghỉ phép năm');
      if (_leaveType == 'Nghỉ phép năm' && availableTypes.isNotEmpty) {
        _leaveType = availableTypes[0];
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _leaveType,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
          items: availableTypes.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))));
          }).toList(),
          onChanged: (newValue) => setState(() => _leaveType = newValue!),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isFrom) {
    final date = isFrom ? _fromDate : _toDate;
    return GestureDetector(
      onTap: () => _selectDate(context, isFrom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Text('${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}', style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF1C6185)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 80),
              ),
              const SizedBox(height: 40),
              const Text('Gửi đơn thành công!', style: TextStyle(fontFamily: 'Nunito', fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              const Text('Yêu cầu của bạn đã được gửi tới quản lý. Vui lòng chờ thông báo duyệt đơn từ hệ thống.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Nunito', fontSize: 16, color: Color(0xFF64748B), height: 1.5)),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C6185),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1C6185).withOpacity(0.3),
                  ),
                  child: const Text('Quay về trang chủ', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BalanceCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
