import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/notifications/provider/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_pecha/features/notifications/application/notification_provider.dart';

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
    if (value) {
      try {
        await ref
            .read(notificationProvider.notifier)
            .enableDailyReminder(
              time: selectedTime,
              title:
                  AppLocalizations.of(
                    context,
                  )?.dailyPracticeNotificationTitle ??
                  'Daily Practice Reminder',
              body:
                  AppLocalizations.of(context)?.timeForDailyPractice ??
                  'It\'s time for your daily practice.',
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
    // Watch the provider to rebuild when data changes
    final state = ref.watch(notificationProvider);

    // Use provider state directly
    final isEnabled = state.isEnabled;
    final selectedTime =
        state.reminderTime ?? const TimeOfDay(hour: 8, minute: 0);
    final hasPermission = state.hasPermission;
    final localizations = AppLocalizations.of(context)!;
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
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Please turn on Notifications',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please enable notifications to receive daily practice reminders.',
                        textAlign: TextAlign.center,
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
                            // open app settings
                            openNotificationSettings();
                          }
                        },
                        child: Text('Enable Notifications'),
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
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        title: Text(
                          'Daily Practice',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          "Get notification of your daily to practices",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: isEnabled,
                        onChanged: (v) => _toggleNotifications(v, selectedTime),
                      ),
                      if (isEnabled) ...[
                        ListTile(
                          title: Text(
                            'Select Time',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            selectedTime.format(context),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(context, selectedTime),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (state.isLoading) ...[
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
