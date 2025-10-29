import 'package:flutter_pecha/features/onboarding/application/onboarding_notifier.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_state.dart';
import 'package:flutter_pecha/features/onboarding/data/providers/onboarding_datasource_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider for onboarding state management
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
      final repository = ref.watch(onboardingRepositoryProvider);
      return OnboardingNotifier(repository);
    });
