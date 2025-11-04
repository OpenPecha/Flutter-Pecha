import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _localStorageService;

  LocaleNotifier({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService,
      super(const Locale("en")) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final locale = await _localStorageService.get<String>(StorageKeys.locale);
    if (locale != null) {
      state = Locale(locale);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final isSupported = L10n.all.any(
      (l) => l.languageCode == locale.languageCode,
    );
    if (isSupported) {
      await _localStorageService.set(StorageKeys.locale, locale.languageCode);
    } else {
      throw Exception("Locale ${locale.languageCode} is not supported");
    }
  }
}

/// Provider for managing the app's current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(
    localStorageService: ref.read(localStorageServiceProvider),
  ),
);
