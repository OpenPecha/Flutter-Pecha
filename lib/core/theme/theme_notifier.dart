import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalStorageService _localStorageService;

  ThemeModeNotifier({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService,
      super(ThemeMode.system) {
    _loadThemeMode();
  }

  // Load theme mode from local storage if available
  Future<void> _loadThemeMode() async {
    final themeIndex = await _localStorageService.get<int>(
      AppStorageKeys.themeMode,
    );
    debugPrint('themeIndex: $themeIndex');
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    debugPrint('setting theme mode: ${mode.index}');
    await _localStorageService.set<int>(AppStorageKeys.themeMode, mode.index);
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    debugPrint('toggling theme mode: ${newMode.index}');
    setTheme(newMode);
  }
}

/// Provider for managing theme mode (light/dark/system)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(
    localStorageService: ref.read(localStorageServiceProvider),
  ),
);
