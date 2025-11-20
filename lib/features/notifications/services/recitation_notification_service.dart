import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';

/// Service for managing recitation reminders
/// Handles scheduling and managing daily recitation notifications
/// Uses the shared notification plugin from NotificationService
class RecitationNotificationService {
  static final RecitationNotificationService _instance =
      RecitationNotificationService._internal();
  factory RecitationNotificationService() => _instance;
  RecitationNotificationService._internal();

  // Use the shared notification plugin from NotificationService
  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      NotificationService().notificationsPlugin;

  static const String _recitationReminderKey = 'recitation_reminder_time';
  static const String _recitationReminderEnabledKey =
      'recitation_reminder_enabled';

  /// Schedule a recitation reminder notification
  Future<void> scheduleRecitationReminder({
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

      debugPrint('📿 Scheduling recitation notification for: $scheduledDate');
      debugPrint('🔔 Title: $title, Body: $body');

      // Save the reminder time and enable the notification in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _recitationReminderKey,
        '${scheduledTime.hour}:${scheduledTime.minute}',
      );
      await prefs.setBool(_recitationReminderEnabledKey, true);

      // Schedule the notification with unique ID for recitation
      await notificationsPlugin.zonedSchedule(
        recitationNotificationId,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            recitationNotificationChannelId,
            recitationNotificationChannelName,
            channelDescription: recitationNotificationChannelDescription,
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
        '✅ Recitation notification scheduled successfully with ID: $recitationNotificationId',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling recitation notification: $e');
      rethrow;
    }
  }

  /// Cancel the recitation reminder
  Future<void> cancelRecitationReminder() async {
    await notificationsPlugin.cancel(recitationNotificationId);

    // Update preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recitationReminderEnabledKey, false);
  }

  /// Get the saved recitation reminder time
  Future<TimeOfDay?> getRecitationReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_recitationReminderKey);
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

  /// Check if recitation reminder is enabled
  Future<bool> isRecitationReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_recitationReminderEnabledKey) ?? false;
  }

  /// Update the recitation reminder time
  Future<void> updateRecitationReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    if (await isRecitationReminderEnabled()) {
      await scheduleRecitationReminder(
        scheduledTime: time,
        title: title,
        body: body,
      );
    }
  }
}
