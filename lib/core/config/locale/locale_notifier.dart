import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_storage_keys.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _localStorageService;
  bool _isInitialized = false;

  LocaleNotifier({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService,
      super(const Locale("en")) {
    // Initialize locale asynchronously, but mark initialization as started
    _initializeLocale();
  }

  /// Initialize locale from storage
  /// This method ensures the locale is loaded before the notifier is used
  Future<void> _initializeLocale() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final locale = await _localStorageService.get<String>(
        AppStorageKeys.locale,
      );
      if (locale != null) {
        state = Locale(locale);
      }
    } catch (e) {
      // If loading fails, keep the default locale
      // Error is silently handled to prevent app crash
    }
  }

  /// Ensure locale is loaded before accessing state
  /// This can be called by consumers if they need to ensure initialization
  Future<void> ensureInitialized() async {
    await _initializeLocale();
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final isSupported = L10n.all.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (isSupported) {
      await _localStorageService.set(
        AppStorageKeys.locale,
        locale.languageCode,
      );
    } else {
      throw Exception("Locale ${locale.languageCode} is not supported");
    }
  }

  /// Maps onboarding language preference to app locale
  ///
  /// Onboarding uses strings like 'tibetan', 'english', 'chinese'
  /// This maps them to Flutter locale codes: 'bo', 'en', 'zh'
  Future<void> setLocaleFromOnboardingPreference(
    String? languagePreference,
  ) async {
    if (languagePreference == null) return;

    Locale? locale;
    switch (languagePreference.toLowerCase()) {
      case 'tibetan':
        locale = const Locale('bo');
        break;
      case 'english':
        locale = const Locale('en');
        break;
      case 'chinese':
        locale = const Locale('zh');
        break;
      default:
        // Unknown preference, don't change locale
        return;
    }

    // Only set if the locale is supported
    if (L10n.all.any((l) => l.languageCode == locale!.languageCode)) {
      await setLocale(locale);
    }
  }
}

/// Provider for managing the app's current locale
/// The locale is loaded asynchronously from storage on first access
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final notifier = LocaleNotifier(
    localStorageService: ref.read(localStorageServiceProvider),
  );
  // Ensure locale is initialized when provider is first created
  // This happens asynchronously but starts immediately
  notifier.ensureInitialized();
  return notifier;
});
