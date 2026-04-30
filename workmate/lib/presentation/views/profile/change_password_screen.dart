import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;
  bool _success = false;
  final _otpCtrl = TextEditingController();
  int _step = 1; // 1=form, 2=otp, 3=success

  @override
  void dispose() {
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Thay đổi mật khẩu', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 17)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _step == 1 ? _buildStep1() : _step == 2 ? _buildStep2() : _buildStep3(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(child: Text('Để đảm bảo bảo mật, bạn cần xác thực OTP trước khi thay đổi mật khẩu.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 12, color: AppColors.warning))),
        ]),
      ),
      const SizedBox(height: 24),

      _FieldLabel('MẬT KHẨU MỚI'),
      const SizedBox(height: 8),
      _PwField(controller: _newPwCtrl, hint: 'Tối thiểu 8 ký tự', obscure: _obscureNew,
        onToggle: () => setState(() => _obscureNew = !_obscureNew)),
      const SizedBox(height: 16),

      _FieldLabel('NHẬP LẠI MẬT KHẨU MỚI'),
      const SizedBox(height: 8),
      _PwField(controller: _confirmPwCtrl, hint: 'Nhập lại mật khẩu', obscure: _obscureConfirm,
        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
      const SizedBox(height: 24),

      _FieldLabel('XÁC THỰC OTP'),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: TextField(controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: 6,
            decoration: const InputDecoration(hintText: 'Nhập mã 6 số', border: InputBorder.none, counterText: '', contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintStyle: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textHint)),
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 4)),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final authVM = context.read<AuthViewModel>();
            if (authVM.currentUser == null) return;
            try {
              await authVM.sendOTP(authVM.currentUser!.id);
              setState(() => _otpSent = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mã OTP đã được gửi vào email của bạn'), backgroundColor: AppColors.success));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi: ${authVM.errorMessage}'), backgroundColor: AppColors.error));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
            child: const Text('Gửi OTP', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
        ),
      ]),
      const SizedBox(height: 28),
 
      SizedBox(width: double.infinity, height: 52,
        child: Consumer<AuthViewModel>(
          builder: (ctx, vm, _) => ElevatedButton(
            onPressed: () async {
              if (_newPwCtrl.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu phải có ít nhất 8 ký tự'), backgroundColor: AppColors.error)); return;
              }
              if (_newPwCtrl.text != _confirmPwCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu không khớp'), backgroundColor: AppColors.error)); return;
              }
              if (_otpCtrl.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã OTP 6 số'), backgroundColor: AppColors.error)); return;
              }
              
              final success = await vm.changePasswordWithOTP(
                vm.currentUser!.id, 
                _newPwCtrl.text, 
                _otpCtrl.text
              );

              if (success) {
                setState(() => _step = 3);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi mật khẩu thất bại. OTP không đúng hoặc hết hạn.'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: vm.isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : const Text('Xác nhận & Đổi mật khẩu', style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStep2() => const SizedBox(); // Not used in current flow

  Widget _buildStep3() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 60),
      Container(width: 88, height: 88, decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 48)),
      const SizedBox(height: 24),
      const Text('Đổi mật khẩu thành công!', style: TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Mật khẩu của bạn đã được cập nhật.\nVui lòng đăng nhập lại.', textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 32),
      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Hoàn thành', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ]));
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1));
}

class _PwField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  const _PwField({required this.controller, required this.hint, required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: TextField(
      controller: controller, obscureText: obscure,
      style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: AppColors.textHint),
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.textSecondary), onPressed: onToggle),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}
