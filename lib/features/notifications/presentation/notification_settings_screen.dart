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
  TimeOfDay? _selectedTime;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    final state = ref.read(notificationProvider);
    setState(() {
      _isEnabled = state.isEnabled;
      _selectedTime = state.reminderTime ?? const TimeOfDay(hour: 8, minute: 0);
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      if (_selectedTime != null) {
        try {
          await ref
              .read(notificationProvider.notifier)
              .enableDailyReminder(
                time: _selectedTime!,
                title:
                    AppLocalizations.of(context)?.dailyPracticeReminder ??
                    'Daily Practice Reminder',
                body:
                    AppLocalizations.of(context)?.timeForDailyPractice ??
                    'Time for your daily practice! 🙏',
              );
          setState(() {
            _isEnabled = true;
          });
          _showSuccessMessage('Daily reminders enabled');
        } catch (e) {
          _showErrorMessage('Failed to enable notifications: $e');
        }
      }
    } else {
      try {
        await ref.read(notificationProvider.notifier).disableDailyReminder();
        setState(() {
          _isEnabled = false;
        });
        _showSuccessMessage('Daily reminders disabled');
      } catch (e) {
        _showErrorMessage('Failed to disable notifications: $e');
      }
    }
  }

  Future<void> _updateReminderTime() async {
    if (_selectedTime != null && _isEnabled) {
      try {
        await ref
            .read(notificationProvider.notifier)
            .updateReminderTime(_selectedTime!);
        _showSuccessMessage('Reminder time updated');
      } catch (e) {
        _showErrorMessage('Failed to update reminder time: $e');
      }
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
    final state = ref.watch(notificationProvider);

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.dailyPracticeReminders ??
                          'Daily Practice Reminders',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(
                            context,
                          )?.dailyPracticeRemindersDescription ??
                          'Get reminded daily to practice your meditation and prayers',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)?.enableReminders ??
                            'Enable Reminders',
                      ),
                      subtitle: Text(
                        _isEnabled
                            ? AppLocalizations.of(context)?.remindersEnabled ??
                                'Reminders are active'
                            : AppLocalizations.of(context)?.remindersDisabled ??
                                'Reminders are inactive',
                      ),
                      value: _isEnabled,
                      onChanged: _toggleNotifications,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isEnabled) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.reminderTime ??
                            'Reminder Time',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)?.selectTime ??
                              'Select Time',
                        ),
                        subtitle: Text(
                          _selectedTime?.format(context) ?? 'No time selected',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(context),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateReminderTime,
                          child: Text(
                            AppLocalizations.of(context)?.updateTime ??
                                'Update Time',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
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
                          AppLocalizations.of(context)?.sendTestNotification ??
                              'Send Test Notification',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
