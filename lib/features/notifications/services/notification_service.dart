import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static const String _dailyReminderKey = 'daily_reminder_time';
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled';
  // Add a static router reference
  static GoRouter? _router;

  // Method to set the router reference
  static void setRouter(GoRouter router) {
    _router = router;
  }

  bool get isInitialized => _isInitialized;

  /// Initialize
  Future<void> initialize() async {
    if (_isInitialized) return; // prevent re-initialization

    // initialize timezone
    tz.initializeTimeZones();
    final currentTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimezone));

    // Android initialization
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestSoundPermission: true,
          requestBadgePermission: true,
        );

    // initialization settings
    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // initialize the plugin
    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  // TODO: request permission for notifications

  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to home using the global router
    if (_router != null) {
      _router!.go('/home');
    }
  }

  // schedule notification
  Future<void> scheduledNotification({
    int id = 1,
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // save the reminder time and enable the notification in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _dailyReminderKey,
      '${scheduledTime.hour}:${scheduledTime.minute}',
    );
    await prefs.setBool(_dailyReminderEnabledKey, true);

    // schedule the notification
    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_practice_reminder',
          'Daily Practice Reminder',
          channelDescription: 'Reminds you to practice daily',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification({int id = 1}) async {
    await notificationsPlugin.cancel(id);

    // Update preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, false);
  }

  Future<TimeOfDay?> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_dailyReminderKey);
    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
    return null;
  }

  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyReminderEnabledKey) ?? false;
  }

  Future<void> updateDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    if (await isDailyReminderEnabled()) {
      await scheduledNotification(
        scheduledTime: time,
        title: title,
        body: body,
      );
    }
  }

  // Method to show immediate notification (for testing)
  Future<void> showTestNotification({
    required String title,
    required String body,
  }) async {
    await notificationsPlugin.show(
      999, // Test notification ID
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_notification',
          'Test Notifications',
          channelDescription: 'For testing notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
