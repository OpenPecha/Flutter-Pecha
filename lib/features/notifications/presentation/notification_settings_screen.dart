import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/notifications/provider/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
// import 'package:flutter_pecha/features/notifications/application/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

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
    if (selectedTime != pickedTime) {
      _updateReminderTime(pickedTime!);
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
        _showErrorMessage('Failed to enable notifications: $e');
      }
    } else {
      try {
        await ref.read(notificationProvider.notifier).disableDailyReminder();
        _showSuccessMessage('Daily reminders disabled');
      } catch (e) {
        _showErrorMessage('Failed to disable notifications: $e');
      }
    }
  }

  Future<void> _updateReminderTime(TimeOfDay time) async {
    try {
      await ref.read(notificationProvider.notifier).updateReminderTime(time);
      _showSuccessMessage('Reminder time updated');
    } catch (e) {
      _showErrorMessage('Failed to update reminder time: $e');
    }
  }

  Future<void> _testNotification() async {
    try {
      await ref.read(notificationProvider.notifier).showTestNotification();
      _showSuccessMessage('Test notification sent!');
    } catch (e) {
      _showErrorMessage('Failed to send test notification: $e');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.notificationSettings ??
              'Notification Settings',
        ),
      ),
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
                            _showPermissionDeniedDialog();
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
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.testNotifications ??
                            'Test Notifications',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(
                              context,
                            )?.testNotificationsDescription ??
                            'Send a test notification to verify everything is working',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _testNotification,
                          icon: const Icon(Icons.notifications),
                          label: Text(
                            AppLocalizations.of(
                                  context,
                                )?.sendTestNotification ??
                                'Send Test Notification',
                          ),
                        ),
                      ),
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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Permission Denied'),
            content: Text(
              'Notifications are disabled. You can enable them in your device settings:\n\n'
              'Settings > Apps > Pecha > Notifications',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Open app settings (requires permission_handler package)
                  // AppSettings.openAppSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
    );
  }
}
