import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_state.dart';
import 'package:flutter_pecha/features/onboarding/data/onboarding_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _logger = AppLogger('OnboardingNotifier');

/// Notifier for managing onboarding flow state
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._repository) : super(OnboardingState.initial()) {
    loadSavedPreferences();
  }

  final OnboardingRepository _repository;

  /// Load saved preferences from local storage on initialization
  Future<void> loadSavedPreferences() async {
    try {
      final saved = await _repository.loadPreferences();
      if (saved != null) {
        state = state.copyWithPreferences(saved);
        _logger.debug('Loaded saved preferences');
      }
    } catch (e) {
      _logger.error('Error loading saved preferences', e);
    }
  }

  /// Set preferred language and save locally
  Future<void> setPreferredLanguage(String language) async {
    final updated = state.preferences.copyWith(preferredLanguage: language);
    state = state.copyWithPreferences(updated);
    await savePreferencesLocally();
  }

  /// Navigate to next page
  void goToNextPage() {
    state = state.copyWithPage(state.currentPage + 1);
  }

  /// Navigate to previous page
  void goToPreviousPage() {
    if (state.currentPage > 0) {
      state = state.copyWithPage(state.currentPage - 1);
    }
  }

  /// Save preferences to local storage
  Future<void> savePreferencesLocally() async {
    try {
      await _repository.savePreferences(state.preferences, saveRemote: false);
    } catch (e) {
      _logger.error('Error saving preferences locally', e);
      state = state.copyWithError('Failed to save preferences: $e');
    }
  }

  /// Submit preferences to local storage and mark onboarding complete
  Future<void> submitPreferences() async {
    state = state.copyWithLoading(true);
    try {
      await _repository.completeOnboarding(state.preferences);
      state = state.copyWithLoading(false);
    } catch (e) {
      _logger.error('Error submitting preferences', e);
      // Don't show error to user, preferences are saved locally
      state = state.copyWithLoading(false);
    }
  }

  /// Clear all preferences and reset state
  Future<void> clearPreferences() async {
    try {
      await _repository.clearPreferences();
      state = OnboardingState.initial();
    } catch (e) {
      _logger.error('Error clearing preferences', e);
    }
  }
}
