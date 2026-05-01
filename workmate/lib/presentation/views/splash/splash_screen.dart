import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/constants/app_text_styles.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn))
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack))
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        final authVM = context.read<AuthViewModel>();
        await authVM.checkLoginStatus();
        if (mounted) {
          if (authVM.isLoggedIn) {
            Navigator.pushReplacementNamed(context, AppRoutes.main);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            colors: [
              Color(0xFFBAE2FE),
              Color(0xFFF5F7F9),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        size: 80,
                        color: Color(0xFF1C6185),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App Name
                Text(
                  'WorkMate',
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Nâng tầm hiệu suất công việc',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            // Footer
            Positioned(
              bottom: 40,
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 16,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SECURE WORKSPACE',
                    style: AppTextStyles.labelSmall.copyWith(
                      letterSpacing: 2,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
