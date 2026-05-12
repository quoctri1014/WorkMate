import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quên mật khẩu',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.blue.withOpacity(0.1) : AppColors.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nhập email đã đăng ký. Chúng tôi sẽ gửi link đặt lại mật khẩu.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[100] : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'EMAIL ĐÃ ĐĂNG KÝ',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'example@company.com',
              hintStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
              prefixIcon: Icon(Icons.email_outlined,
                  size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Consumer<AuthViewModel>(
          builder: (context, vm, _) => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      if (_emailCtrl.text.isEmpty) return;
                      await vm.resetPassword(_emailCtrl.text.trim());
                      setState(() => _sent = true);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: vm.isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : const Text(
                      'Gửi yêu cầu',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.green.withOpacity(0.1) : AppColors.successLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.mark_email_read_rounded,
                color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 24),
          Text(
            'Đã gửi thành công!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kiểm tra email của bạn và làm theo\nhướng dẫn để đặt lại mật khẩu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Quay về đăng nhập',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
