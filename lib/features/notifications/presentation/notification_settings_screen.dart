import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/notifications/provider/notification_provider.dart';
import 'package:flutter_pecha/features/notifications/provider/recitation_notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});
  static const String routeName = '/notifications';

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  Future<void> _selectTime(BuildContext context, TimeOfDay selectedTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null && selectedTime != pickedTime) {
      _updateReminderTime(pickedTime);
    }
  }

  Future<void> _toggleNotifications(bool value, TimeOfDay selectedTime) async {
    final localizations = AppLocalizations.of(context)!;
    if (value) {
      try {
        await ref
            .read(notificationProvider.notifier)
            .enableDailyReminder(
              time: selectedTime,
              title: localizations.dailyPracticeNotificationTitle,
              body: localizations.timeForDailyPractice,
            );

        _showSuccessMessage('Daily reminders enabled');
      } catch (e) {
        _showErrorMessage(
          'Failed to enable notifications. Please try again later.',
        );
      }
    } else {
      try {
        await ref.read(notificationProvider.notifier).disableDailyReminder();
        _showSuccessMessage('Daily reminders disabled');
      } catch (e) {
        _showErrorMessage(
          'Failed to disable notifications. Please try again later.',
        );
      }
    }
  }

  Future<void> _updateReminderTime(TimeOfDay time) async {
    try {
      await ref.read(notificationProvider.notifier).updateReminderTime(time);
      _showSuccessMessage('Reminder time updated');
    } catch (e) {
      _showErrorMessage(
        'Failed to update reminder time. Please try again later.',
      );
    }
  }

  // Recitation notification methods
  Future<void> _toggleRecitationNotifications(
    bool value,
    TimeOfDay selectedTime,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    if (value) {
      try {
        await ref
            .read(recitationNotificationProvider.notifier)
            .enableRecitationReminder(
              time: selectedTime,
              title: localizations.recitation_reminder,
              body: localizations.moment_to_pray,
            );

        _showSuccessMessage('Recitation reminders enabled');
      } catch (e) {
        _showErrorMessage(
          'Failed to enable notifications. Please try again later.',
        );
      }
    } else {
      try {
        await ref
            .read(recitationNotificationProvider.notifier)
            .disableRecitationReminder();
        _showSuccessMessage('Recitation reminders disabled');
      } catch (e) {
        _showErrorMessage(
          'Failed to disable notifications. Please try again later.',
        );
      }
    }
  }

  Future<void> _updateRecitationReminderTime(TimeOfDay time) async {
    try {
      await ref
          .read(recitationNotificationProvider.notifier)
          .updateReminderTime(time);
      _showSuccessMessage('Recitation reminder time updated');
    } catch (e) {
      _showErrorMessage(
        'Failed to update reminder time. Please try again later.',
      );
    }
  }

  Future<void> _selectRecitationTime(
    BuildContext context,
    TimeOfDay selectedTime,
  ) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (pickedTime != null && selectedTime != pickedTime) {
      _updateRecitationReminderTime(pickedTime);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the providers to rebuild when data changes
    final state = ref.watch(notificationProvider);
    final recitationState = ref.watch(recitationNotificationProvider);

    // Use provider state directly
    final isEnabled = state.isEnabled;
    final selectedTime =
        state.reminderTime ?? const TimeOfDay(hour: 9, minute: 0);
    final hasPermission = state.hasPermission;

    // Recitation state
    final isRecitationEnabled = recitationState.isEnabled;
    final recitationSelectedTime =
        recitationState.reminderTime ?? const TimeOfDay(hour: 8, minute: 0);

    final localizations = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final languageCode = locale.languageCode;
    final titleFontSize = languageCode == 'bo' ? 20.0 : 16.0;
    final subtitleFontSize = languageCode == 'bo' ? 18.0 : 14.0;
    final bodyFontSize = languageCode == 'bo' ? 16.0 : 12.0;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.notification_settings)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Status Card
            if (!hasPermission) ...[
              Card(
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Theme.of(context).colorScheme.error,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        localizations.notification_enable_message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: subtitleFontSize),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final granted =
                              await ref
                                  .read(notificationServiceProvider)
                                  .requestPermission();
                          if (granted) {
                            ref
                                .read(notificationProvider.notifier)
                                .checkPermissionStatus();
                          } else {
                            openNotificationSettings();
                          }
                        },
                        child: Text(
                          localizations.enable_notification,
                          style: TextStyle(fontSize: titleFontSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            if (hasPermission) ...[
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: Colors.grey,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        title: Text(
                          localizations.notification_daily_practice,
                          style: TextStyle(fontSize: titleFontSize),
                        ),
                        value: isEnabled,
                        onChanged: (v) => _toggleNotifications(v, selectedTime),
                      ),
                      if (isEnabled) ...[
                        ListTile(
                          title: Text(
                            localizations.notification_select_time,
                            style: TextStyle(fontSize: subtitleFontSize),
                          ),
                          subtitle: Text(
                            selectedTime.format(context),
                            style: TextStyle(fontSize: bodyFontSize),
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, selectedTime),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: Colors.grey,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        title: Text(
                          localizations.notification_daily_recitation,
                          style: TextStyle(fontSize: titleFontSize),
                        ),
                        value: isRecitationEnabled,
                        onChanged:
                            (v) => _toggleRecitationNotifications(
                              v,
                              recitationSelectedTime,
                            ),
                      ),
                      if (isRecitationEnabled) ...[
                        ListTile(
                          title: Text(
                            localizations.notification_select_time,
                            style: TextStyle(fontSize: subtitleFontSize),
                          ),
                          subtitle: Text(
                            recitationSelectedTime.format(context),
                            style: TextStyle(fontSize: bodyFontSize),
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap:
                              () => _selectRecitationTime(
                                context,
                                recitationSelectedTime,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (state.isLoading || recitationState.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }
}
