import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';

/// State for onboarding flow management
class OnboardingState {
  const OnboardingState({
    required this.preferences,
    required this.currentPage,
    required this.isLoading,
    this.error,
  });

  final OnboardingPreferences preferences;
  final int currentPage;
  final bool isLoading;
  final String? error;

  /// Initial state
  factory OnboardingState.initial() {
    return const OnboardingState(
      preferences: OnboardingPreferences(),
      currentPage: 0,
      isLoading: false,
    );
  }

  /// Loading state
  OnboardingState copyWithLoading(bool loading) {
    return OnboardingState(
      preferences: preferences,
      currentPage: currentPage,
      isLoading: loading,
      error: error,
    );
  }

  /// Success state with updated preferences
  OnboardingState copyWithPreferences(OnboardingPreferences newPreferences) {
    return OnboardingState(
      preferences: newPreferences,
      currentPage: currentPage,
      isLoading: false,
      error: null,
    );
  }

  /// Error state
  OnboardingState copyWithError(String errorMessage) {
    return OnboardingState(
      preferences: preferences,
      currentPage: currentPage,
      isLoading: false,
      error: errorMessage,
    );
  }

  /// Update current page
  OnboardingState copyWithPage(int page) {
    return OnboardingState(
      preferences: preferences,
      currentPage: page,
      isLoading: isLoading,
      error: error,
    );
  }

  /// General copy with method
  OnboardingState copyWith({
    OnboardingPreferences? preferences,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      preferences: preferences ?? this.preferences,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'OnboardingState(preferences: $preferences, currentPage: $currentPage, isLoading: $isLoading, error: $error)';
  }
}
