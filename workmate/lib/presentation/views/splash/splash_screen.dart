import 'package:flutter/material.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/constants/app_text_styles.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        final prefs = await SharedPreferences.getInstance();
        final bool isFirstRun = prefs.getBool('is_first_run') ?? true;

        if (isFirstRun) {
          await prefs.setBool('is_first_run', false);
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFBAE2FE), const Color(0xFFF5F7F9)],
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: Theme.of(context).brightness == Brightness.dark ? null : [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Transform.scale(
                          scale: 1.6,
                          child: Transform.translate(
                            offset: const Offset(12, 16),
                            child: Image.asset(
                              'assets/icons/app_icon.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Nâng tầm hiệu suất công việc',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
