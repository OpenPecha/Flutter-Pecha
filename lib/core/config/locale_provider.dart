import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing the app's current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(const Locale("en")); // default to English

  void setLocale(Locale? locale) {
    state = locale;
  }
}
