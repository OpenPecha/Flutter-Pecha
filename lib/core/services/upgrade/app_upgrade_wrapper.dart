import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'app_upgrade_config.dart';

/// A wrapper widget that adds app upgrade checking functionality.
///
/// Wraps child widgets with [UpgradeAlert] to automatically check for
/// and prompt users about app updates from the App Store / Play Store.
///
/// Usage:
/// ```dart
/// AppUpgradeWrapper(
///   child: YourMainScreen(),
/// )
/// ```
class AppUpgradeWrapper extends StatelessWidget {
  final Widget child;

  /// Optional minimum app version to force updates.
  /// Users below this version will not see "Ignore" or "Later" buttons.
  final String? minAppVersion;

  /// Whether to show debug logging (disable in production).
  final bool debugLogging;

  /// Force display dialog for testing (shows even if no update available).
  /// Set to true during development to test the dialog UI.
  final bool debugDisplayAlways;

  /// Duration to wait before showing the prompt again after user taps "Later".
  final Duration durationUntilAlertAgain;

  const AppUpgradeWrapper({
    super.key,
    required this.child,
    this.minAppVersion,
    this.debugLogging = false,
    this.debugDisplayAlways = false,
    this.durationUntilAlertAgain = const Duration(days: 3),
  });

  @override
  Widget build(BuildContext context) {
    final upgrader = AppUpgradeConfig.createUpgrader(
      minAppVersion: minAppVersion,
      debugLogging: debugLogging,
      debugDisplayAlways: debugDisplayAlways,
      durationUntilAlertAgain: durationUntilAlertAgain,
      messages: AppUpgradeConfig.getMessages(context),
    );

    return UpgradeAlert(
      upgrader: upgrader,
      dialogStyle: AppUpgradeConfig.getDialogStyle(),
      showIgnore: false,
      showLater: true,
      showReleaseNotes: false,
      child: child,
    );
  }
}
