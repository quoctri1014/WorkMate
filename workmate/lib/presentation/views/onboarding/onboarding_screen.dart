import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'package:workmate/core/utils/support_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppColors.buttonShadow,
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'WorkMate',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kiến tạo không gian làm việc số\nhiện đại và tinh gọn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Features list
                      _FeatureRow(
                        icon: Icons.fingerprint_rounded,
                        iconColor: AppColors.primary,
                        title: 'Chấm công thông minh',
                        subtitle: 'Face ID, GPS, WiFi đa phương thức',
                      ),
                      const SizedBox(height: 16),
                      _FeatureRow(
                        icon: Icons.bar_chart_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        title: 'Thống kê chi tiết',
                        subtitle: 'Biểu đồ giờ làm, lương tháng trực quan',
                      ),
                      const SizedBox(height: 16),
                      _FeatureRow(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFFF9800),
                        title: 'Thông báo realtime',
                        subtitle: 'Duyệt nghỉ phép, OT tức thì',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    // Đăng nhập button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.login);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white),
                        label: const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    // "Liên hệ hỗ trợ" removed as requested
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: () => SupportUtils.showSupportOptions(context),
                      icon: const Icon(Icons.help_outline_rounded,
                          size: 18, color: AppColors.textSecondary),
                      label: const Text(
                        'Trung tâm trợ giúp',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'WORKMATE ECOSYSTEM © 2025',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: AppColors.textSecondary.withOpacity(0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
