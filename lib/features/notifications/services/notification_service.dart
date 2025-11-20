import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/app/presentation/skeleton_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static const String _dailyReminderKey = 'daily_reminder_time';
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled';
  // Add static references for navigation
  static GoRouter? _router;
  static ProviderContainer? _container;

  // Method to set the router reference
  static void setRouter(GoRouter router) {
    _router = router;
  }

  // Method to set the provider container
  static void setContainer(ProviderContainer container) {
    _container = container;
  }

  bool get isInitialized => _isInitialized;

  /// Initialize without requesting permissions (for early app initialization)
  Future<void> initializeWithoutPermissions() async {
    if (_isInitialized) return; // prevent re-initialization

    // initialize timezone
    tz.initializeTimeZones();
    final currentTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimezone));

    // Android initialization - do NOT request permissions
    // Use drawable resource for notification icon (not mipmap)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    // iOS initialization - do NOT request permissions
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
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

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Daily practice channel
      const AndroidNotificationChannel dailyPracticeChannel =
          AndroidNotificationChannel(
            androidNotificationChannelId,
            androidNotificationChannelName,
            description: androidNotificationChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      // Recitation reminder channel
      const AndroidNotificationChannel recitationChannel =
          AndroidNotificationChannel(
            recitationNotificationChannelId,
            recitationNotificationChannelName,
            description: recitationNotificationChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      // Test notification channel
      const AndroidNotificationChannel testChannel =
          AndroidNotificationChannel(
            'test_notification',
            'Test Notifications',
            description: 'For testing notifications',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

      // Create all channels
      await androidImplementation.createNotificationChannel(
        dailyPracticeChannel,
      );
      await androidImplementation.createNotificationChannel(recitationChannel);
      await androidImplementation.createNotificationChannel(testChannel);

      debugPrint('✅ Android notification channels created successfully');
    }
  }

  /// Initialize with permission request (legacy method)
  Future<void> initialize() async {
    await initializeWithoutPermissions();
    await requestPermission();
  }

  // Request permission for notifications
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      // Request notification permission
      final bool? granted =
          await androidImplementation?.requestNotificationsPermission();

      // For Android 12+, also request exact alarm permission
      if (granted == true && Platform.isAndroid) {
        await androidImplementation?.requestExactAlarmsPermission();
      }

      return granted ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? granted =
          await androidImplementation?.areNotificationsEnabled();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final NotificationsEnabledOptions? granted =
          await iosImplementation?.checkPermissions();
      return granted?.isEnabled ?? false;
    }
    return false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigate based on notification ID
    if (_router != null && _container != null) {
      // Check notification ID to determine which tab to open
      if (response.id == recitationNotificationId) {
        // Recitation notification - go to recitation tab (index 2)
        _container!.read(bottomNavIndexProvider.notifier).state = 2;
      } else {
        // Daily practice or default - go to home tab (index 0)
        _container!.read(bottomNavIndexProvider.notifier).state = 0;
      }
      _router!.go('/home');
    }
  }

  // schedule notification
  Future<void> scheduledNotification({
    required String title,
    required String body,
    required TimeOfDay scheduledTime,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      // If the scheduled time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      debugPrint('📅 Scheduling notification for: $scheduledDate');
      debugPrint('🔔 Title: $title, Body: $body');

      // save the reminder time and enable the notification in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _dailyReminderKey,
        '${scheduledTime.hour}:${scheduledTime.minute}',
      );
      await prefs.setBool(_dailyReminderEnabledKey, true);

      // schedule the notification
      await notificationsPlugin.zonedSchedule(
        dailyNotificationId,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            androidNotificationChannelId,
            androidNotificationChannelName,
            channelDescription: androidNotificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
            enableVibration: true,
            playSound: true,
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

      debugPrint(
        '✅ Notification scheduled successfully with ID: $dailyNotificationId',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification() async {
    await notificationsPlugin.cancel(dailyNotificationId);

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
          icon: 'ic_notification',
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

// Daily practice notification channel constants
const androidNotificationChannelId = 'daily_practice_reminder';
const androidNotificationChannelName = 'Daily Practice Reminder';
const androidNotificationChannelDescription =
    'Notification for daily practice reminders';
const dailyNotificationId = 1;

// Recitation notification constants (shared with recitation service)
const recitationNotificationChannelId = 'recitation_reminder';
const recitationNotificationChannelName = 'Recitation Reminder';
const recitationNotificationChannelDescription =
    'Notification for recitation reminders';
const recitationNotificationId = 2;
