import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// Configuration for app upgrade prompts.
/// Provides a centralized configuration for the upgrader package.
class AppUpgradeConfig {
  AppUpgradeConfig._();

  /// Creates and returns a configured Upgrader instance.
  ///
  /// Best practices applied:
  /// - Country code detected from user's locale for iOS App Store lookup
  /// - Reasonable duration between prompts (3 days)
  /// - Debug logging disabled in production
  /// - Minimum app version support ready
  static Upgrader createUpgrader({
    String? minAppVersion,
    Duration durationUntilAlertAgain = const Duration(days: 3),
    bool debugLogging = false,
    bool debugDisplayAlways = false,
    UpgraderMessages? messages,
  }) {
    return Upgrader(
      countryCode: _getCountryCode(),
      durationUntilAlertAgain: durationUntilAlertAgain,
      minAppVersion: minAppVersion,
      debugLogging: debugLogging,
      debugDisplayAlways: debugDisplayAlways,
      messages: messages,
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderPlayStore(),
        oniOS: () => UpgraderAppStore(),
      ),
    );
  }

  /// Gets the country code from user's device locale.
  /// iOS needs explicit country code; Android auto-detects.
  static String? _getCountryCode() {
    if (Platform.isIOS) {
      final locale = ui.PlatformDispatcher.instance.locale;
      final countryCode = locale.countryCode;

      return countryCode?.isNotEmpty == true ? countryCode : 'US';
    }
    return null; // Android auto-detects from system locale
  }

  /// Returns platform-appropriate dialog style.
  /// Material for Android, Cupertino for iOS.
  static UpgradeDialogStyle getDialogStyle() {
    if (Platform.isIOS) {
      return UpgradeDialogStyle.cupertino;
    }
    return UpgradeDialogStyle.material;
  }

  /// Creates custom dialog styling that matches the app theme.
  static UpgraderMessages getMessages(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return _AppUpgraderMessages(locale);
  }
}

/// Custom messages for the upgrader dialog.
/// Supports English, Tibetan, and Chinese.
class _AppUpgraderMessages extends UpgraderMessages {
  final Locale locale;

  _AppUpgraderMessages(this.locale);

  @override
  String get title {
    switch (locale.languageCode) {
      case 'bo':
        return 'WeBuddhist གསར་བསྒྱུར།';
      case 'zh':
        return '更新 WeBuddhist';
      default:
        return 'Update WeBuddhist';
    }
  }

  @override
  String get body {
    switch (locale.languageCode) {
      case 'bo':
        return 'ཐོན་རིམ་ {{currentAppStoreVersion}} གསར་བཅོས་དང་བཅས་པ་སླེབས་ཡོད། ད་ལྟའི་ཐོན་རིམ་ {{currentInstalledVersion}} རེད།';
      case 'zh':
        return '版本 {{currentAppStoreVersion}} 已推出，带来全新改进。 您当前的版本是 {{currentInstalledVersion}}。';
      default:
        return 'Version {{currentAppStoreVersion}} is here with new improvements. You have {{currentInstalledVersion}}.';
    }
  }

  @override
  String get buttonTitleUpdate {
    switch (locale.languageCode) {
      case 'bo':
        return 'གསར་བསྐྱར།';
      case 'zh':
        return '立即更新';
      default:
        return 'Update Now';
    }
  }

  @override
  String get buttonTitleLater {
    switch (locale.languageCode) {
      case 'bo':
        return 'ཕྱིས་སུ།';
      case 'zh':
        return '稍后';
      default:
        return 'Later';
    }
  }

  @override
  String get buttonTitleIgnore {
    switch (locale.languageCode) {
      case 'bo':
        return 'མཐོང་མཆི།';
      case 'zh':
        return '忽略';
      default:
        return 'Ignore';
    }
  }

  @override
  String get prompt {
    switch (locale.languageCode) {
      case 'bo':
        return 'ད་ལྟ་གསར་བསྐྱར་གནང་འདོད་དམ།';
      case 'zh':
        return '您想现在更新吗？';
      default:
        return 'Would you like to update now?';
    }
  }

  @override
  String get releaseNotes {
    switch (locale.languageCode) {
      case 'bo':
        return 'གསར་བཏོན་འགྲེལ་བཤད།';
      case 'zh':
        return '更新说明';
      default:
        return 'Release Notes';
    }
  }
}
