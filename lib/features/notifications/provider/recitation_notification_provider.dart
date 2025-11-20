import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recitation_notification_service.dart';
import '../services/notification_service.dart';

/// State class for recitation notifications
class RecitationNotificationState {
  final bool isEnabled;
  final TimeOfDay? reminderTime;
  final bool isLoading;
  final bool hasPermission;

  const RecitationNotificationState({
    this.isEnabled = false,
    this.reminderTime,
    this.isLoading = false,
    this.hasPermission = false,
  });

  RecitationNotificationState copyWith({
    bool? isEnabled,
    TimeOfDay? reminderTime,
    bool? isLoading,
    bool? hasPermission,
  }) {
    return RecitationNotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

/// Notifier for managing recitation notification state
class RecitationNotificationNotifier
    extends StateNotifier<RecitationNotificationState> {
  final RecitationNotificationService _recitationService;
  final NotificationService _notificationService;

  RecitationNotificationNotifier(
    this._recitationService,
    this._notificationService,
  ) : super(const RecitationNotificationState()) {
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final isEnabled = await _recitationService.isRecitationReminderEnabled();
      final reminderTime = await _recitationService.getRecitationReminderTime();
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

  /// Enable recitation reminder with specified time
  Future<void> enableRecitationReminder({
    required TimeOfDay time,
    String title = 'Recitations Reminder',
    String body = 'Take a moment to pray',
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _recitationService.scheduleRecitationReminder(
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

  /// Check notification permission status
  Future<void> checkPermissionStatus() async {
    final hasPermission = await _notificationService.areNotificationsEnabled();
    state = state.copyWith(hasPermission: hasPermission);
  }

  /// Disable recitation reminder
  Future<void> disableRecitationReminder() async {
    state = state.copyWith(isLoading: true);

    try {
      await _recitationService.cancelRecitationReminder();

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

  /// Update the reminder time
  Future<void> updateReminderTime(TimeOfDay time) async {
    if (state.isEnabled) {
      await enableRecitationReminder(time: time);
    }
  }
}

/// Provider for recitation notification state
final recitationNotificationProvider = StateNotifierProvider<
  RecitationNotificationNotifier,
  RecitationNotificationState
>((ref) {
  return RecitationNotificationNotifier(
    RecitationNotificationService(),
    NotificationService(),
  );
});

/// Provider for recitation notification service
final recitationNotificationServiceProvider =
    Provider<RecitationNotificationService>((ref) {
      return RecitationNotificationService();
    });
