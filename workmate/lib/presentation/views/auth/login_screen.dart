import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'package:workmate/core/constants/app_text_styles.dart';
import 'package:workmate/core/utils/support_utils.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    await authVM.loginWithEmployeeCode(_idController.text.trim(), _passwordController.text.trim());

    if (mounted && authVM.isLoggedIn) {
      if (_idController.text.trim().toLowerCase() == 'admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        // Đồng bộ user sang các ViewModel khác
        if (authVM.currentUser != null) {
          context.read<HomeViewModel>().setUser(authVM.currentUser!);
          context.read<ProfileViewModel>().setUser(authVM.currentUser!);
          // Khởi tạo thông báo cho user mới
          context.read<NotificationViewModel>().initForUser(authVM.currentUser!.id);
        }
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    } else if (mounted && authVM.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.loginGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    size: 50,
                    color: Color(0xFF1C6185),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Đăng nhập hệ thống',
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chào mừng bạn đến với WorkMate',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                // Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('MÃ NHÂN VIÊN'),
                      _buildTextField(
                        controller: _idController,
                        hint: 'Nhập mã nhân viên (VD: WM-1234)',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 24),
                      _buildInputLabel('MẬT KHẨU'),
                      _buildTextField(
                        controller: _passwordController,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        isPassword: !_isPasswordVisible,
                        suffixIcon: _isPasswordVisible 
                            ? Icons.visibility_off_outlined 
                            : Icons.visibility_outlined,
                        onSuffixTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                          child: Text(
                            'Quên mật khẩu?',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLoginButton(),
                      // Removed help and support section
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Footer
                Text(
                  'THAM GIA CÙNG 5,000+ ĐỒNG NGHIỆP TRÊN TOÀN CẦU',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.4),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          suffixIcon: suffixIcon != null 
              ? GestureDetector(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon, color: AppColors.textHint, size: 20),
                ) 
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: authVM.isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C6185), // Sử dụng màu xanh đậm đồng nhất với logo
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: authVM.isLoading
                ? const SizedBox(
                    height: 24, 
                    width: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đăng nhập', 
                        style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
