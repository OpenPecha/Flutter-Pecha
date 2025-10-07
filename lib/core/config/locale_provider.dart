import 'package:flutter/material.dart';
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
    final locale = await _prefs.get<String>(StorageKeys.locale);
    if (locale != null) {
      state = Locale(locale);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await _prefs.set(StorageKeys.locale, locale?.languageCode ?? "en");
  }
}
