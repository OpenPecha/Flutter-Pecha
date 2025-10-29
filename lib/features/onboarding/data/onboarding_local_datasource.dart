import 'dart:convert';
import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';

/// Local datasource for onboarding preferences using SharedPreferences
class OnboardingLocalDatasource {
  const OnboardingLocalDatasource({required this.preferencesService});

  final PreferencesService preferencesService;

  /// Save preferences to local storage
  Future<void> savePreferences(OnboardingPreferences prefs) async {
    final jsonString = json.encode(prefs.toJson());
    await preferencesService.set<String>(
      StorageKeys.onboardingPreferences,
      jsonString,
    );
  }

  /// Load preferences from local storage
  Future<OnboardingPreferences?> loadPreferences() async {
    final jsonString = await preferencesService.get<String>(
      StorageKeys.onboardingPreferences,
    );
    if (jsonString == null) return null;
    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return OnboardingPreferences.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Clear preferences from local storage
  Future<void> clearPreferences() async {
    await preferencesService.remove(StorageKeys.onboardingPreferences);
    await preferencesService.remove(StorageKeys.onboardingCompleted);
  }

  /// Check if onboarding has been completed
  Future<bool> hasCompletedOnboarding() async {
    final completed = await preferencesService.get<bool>(
      StorageKeys.onboardingCompleted,
    );
    return completed ?? false;
  }

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    await preferencesService.set<bool>(StorageKeys.onboardingCompleted, true);
  }
}
