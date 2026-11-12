import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings: initSettings);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<void> showLocalPushNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'cleandrop_channel',
    'CleanDrop Live Order Alerts',
    channelDescription: 'Real-time driver and laundry stage notifications',
    importance: Importance.max,
    priority: Priority.high,
    color: Color(0xFF065F46),
  );
  await flutterLocalNotificationsPlugin.show(
    id: Random().nextInt(10000),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails),
  );
}

class AppColors {
  static const Color darkNavy = Color(0xFF0D1B2A);
  static const Color mintAccent = Color(0xFF6EE7B7);
  static const Color deepEmerald = Color(0xFF065F46);
  static const Color softIce = Color(0xFFF4F7FA);
  static const Color tagBlue = Color(0xFFE0F2FE);
  static const Color warningAmber = Color(0xFFFEF3C7);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.softIce,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepEmerald,
      primary: AppColors.darkNavy,
      secondary: AppColors.mintAccent,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.darkNavy,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF09111A),
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: AppColors.mintAccent,
      primary: AppColors.mintAccent,
      secondary: AppColors.deepEmerald,
      surface: const Color(0xFF132232),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1B2A),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF132232),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF1E344B)),
      ),
    ),
  );
}