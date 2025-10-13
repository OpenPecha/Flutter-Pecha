import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the app's current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(ref.read(preferencesServiceProvider)),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  final PreferencesService _prefs;

  LocaleNotifier(this._prefs) : super(const Locale("en")) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final locale = await _prefs.get<String>(StorageKeys.locale);
      if (locale != null) {
        // Validate that the stored locale is supported
        final isSupported = L10n.all.any((l) => l.languageCode == locale);
        if (isSupported) {
          state = Locale(locale);
        } else {
          // If stored locale is not supported, fall back to default "en"
          state = const Locale("en");
        }
      }
    } catch (e) {
      // If storage fails, keep default "en" locale
      state = const Locale("en");
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      await _prefs.set(StorageKeys.locale, locale?.languageCode ?? "en");
    } catch (e) {
      // If storage fails, state is still updated but not persisted
      // This ensures the UI reflects the change even if persistence fails
    }
  }
}
