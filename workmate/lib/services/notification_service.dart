import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmate/data/repositories/api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // 1. Local Notifications Setup
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    
    final InitializationSettings settings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Xử lý khi nhấn vào thông báo (Deep Link)
        print('🔔 Notification clicked: ${details.payload}');
      },
    );

    // 2. Firebase Messaging Setup
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Xử lý thông báo khi app đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        showInstantNotification(
          title: message.notification!.title ?? 'Thông báo',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Xử lý khi nhấn vào thông báo từ trạng thái đóng (Background/Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 App opened from notification: ${message.data}');
    });
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> updateTokenOnServer(int employeeId) async {
    String? token = await getToken();
    if (token != null) {
      await ApiService().updateFcmToken(employeeId, token);
      print('✅ FCM Token updated on server');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meeting_reminder',
          'Meeting Reminder',
          channelDescription: 'Channel for meeting reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notif',
          'Instant Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
