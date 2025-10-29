import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_local_datasource.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_remote_datasource.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';

/// Repository for managing onboarding preferences
/// Aggregates local and remote datasources
class OnboardingRepository {
  const OnboardingRepository({
    required this.localDatasource,
    required this.remoteDatasource,
  });

  final OnboardingLocalDatasource localDatasource;
  final OnboardingRemoteDatasource remoteDatasource;

  /// Save preferences both locally and optionally remotely
  Future<void> savePreferences(
    OnboardingPreferences prefs, {
    bool saveRemote = true,
  }) async {
    // Always save locally first
    await localDatasource.savePreferences(prefs);

    // Optionally save to backend
    // if (saveRemote) {
    //   try {
    //     await remoteDatasource.saveOnboardingPreferences(prefs);
    //   } catch (e) {
    //     debugPrint('Failed to save to backend, kept local copy: $e');
    //     // Don't throw - local save succeeded
    //   }
    // }
  }

  /// Load preferences from local storage
  Future<OnboardingPreferences?> loadPreferences() async {
    return await localDatasource.loadPreferences();
  }

  /// Complete onboarding: save preferences and mark as complete
  Future<void> completeOnboarding(OnboardingPreferences prefs) async {
    // Save preferences locally and remotely
    await savePreferences(prefs, saveRemote: true);

    // Mark onboarding as complete
    await localDatasource.markOnboardingComplete();

    debugPrint('Onboarding completed and marked');
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    return await localDatasource.hasCompletedOnboarding();
  }

  /// Clear all preferences and completion status
  Future<void> clearPreferences() async {
    await localDatasource.clearPreferences();
  }
}
