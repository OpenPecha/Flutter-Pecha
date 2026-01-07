import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

class NotificationState {
  final bool isEnabled;
  final TimeOfDay? reminderTime;
  final bool isLoading;
  final bool hasPermission;

  const NotificationState({
    this.isEnabled = false,
    this.reminderTime,
    this.isLoading = false,
    this.hasPermission = false,
  });

  NotificationState copyWith({
    bool? isEnabled,
    TimeOfDay? reminderTime,
    bool? isLoading,
    bool? hasPermission,
  }) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService)
    : super(const NotificationState()) {
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final isEnabled = await _notificationService.isDailyReminderEnabled();
      final reminderTime = await _notificationService.getDailyReminderTime();
      final hasPermission =
          await _notificationService.areNotificationsEnabled();

      state = state.copyWith(
        isEnabled: isEnabled,
        reminderTime: reminderTime,
        hasPermission: hasPermission,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> enableDailyReminder({
    required TimeOfDay time,
    String title = 'Daily Practice Reminder',
    String body = 'It\'s time for your daily practice.',
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _notificationService.scheduledNotification(
        scheduledTime: time,
        title: title,
        body: body,
      );

      state = state.copyWith(
        isEnabled: true,
        reminderTime: time,
        isLoading: false,
        hasPermission: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> checkPermissionStatus() async {
    final hasPermission = await _notificationService.areNotificationsEnabled();
    state = state.copyWith(hasPermission: hasPermission);
  }

  Future<void> disableDailyReminder() async {
    state = state.copyWith(isLoading: true);

    try {
      await _notificationService.cancelNotification();

      state = state.copyWith(
        isEnabled: false,
        reminderTime: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    if (state.isEnabled) {
      await enableDailyReminder(time: time);
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier(NotificationService());
    });

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
