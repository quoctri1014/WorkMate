import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:workmate/core/constants/app_colors.dart';
import 'package:workmate/core/constants/app_routes.dart';
import 'package:workmate/presentation/viewmodels/viewmodels.dart';
import 'package:workmate/presentation/views/splash/splash_screen.dart';
import 'package:workmate/presentation/views/onboarding/onboarding_screen.dart';
import 'package:workmate/presentation/views/auth/login_screen.dart';
import 'package:workmate/presentation/views/auth/forgot_password_screen.dart';
import 'package:workmate/presentation/views/home/main_nav_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmate/services/face_id_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmate/presentation/views/leave/leave_request_screen.dart';
import 'package:workmate/presentation/views/leave/leave_history_screen.dart';
import 'package:workmate/presentation/views/overtime/ot_request_screen.dart';
import 'package:workmate/presentation/views/overtime/ot_history_screen.dart';
import 'package:workmate/presentation/views/meeting/meeting_screen.dart';
import 'package:workmate/presentation/views/statistics/statistics_screen.dart';
import 'package:workmate/presentation/views/notification/notification_screen.dart';
import 'package:workmate/presentation/views/profile/profile_screen.dart';
import 'package:workmate/presentation/views/profile/change_password_screen.dart';
import 'package:workmate/presentation/views/profile/qr_screen.dart';
import 'package:workmate/presentation/views/profile/bank_account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo các dịch vụ nền mà không chặn luồng chính quá lâu
  Firebase.initializeApp().then((_) {
    print('✅ Firebase initialized');
    FaceIdService.instance.initialize();
  });

  await NotificationService().init();

  await initializeDateFormatting('vi_VN', null);
  await initializeDateFormatting('vi', null);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const WorkMateApp());
}

class WorkMateApp extends StatelessWidget {
  const WorkMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => AttendanceViewModel()),
        ChangeNotifierProvider(create: (_) => LeaveViewModel()),
        ChangeNotifierProvider(create: (_) => OvertimeViewModel()),
        ChangeNotifierProvider(create: (_) => StatisticsViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => MeetingViewModel()),
      ],
      child: MaterialApp(
        title: 'WorkMate',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => const OnboardingScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
          AppRoutes.main: (_) => const MainNavScreen(),
          
          // Leave
          AppRoutes.leaveRequest: (_) => const LeaveRequestScreen(),
          AppRoutes.leaveHistory: (_) => const LeaveHistoryScreen(),
          
          // Overtime
          AppRoutes.otRequest: (_) => OTRequestScreen(),
          AppRoutes.otHistory: (_) => OTHistoryScreen(),
          
          // Meeting
          AppRoutes.meeting: (_) => MeetingScreen(),
          
          // Other
          AppRoutes.statistics: (_) => StatisticsScreen(),
          AppRoutes.notification: (_) => NotificationScreen(),
          AppRoutes.profile: (_) => ProfileScreen(),
          AppRoutes.changePassword: (_) => ChangePasswordScreen(),
          AppRoutes.qrCode: (_) => QRScreen(),
          AppRoutes.bankAccount: (_) => BankAccountScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}
