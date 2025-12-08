import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_screen_1.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_screen_3.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_screen_5.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/config/router/route_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Wrapper for onboarding screens with Riverpod state management
/// Manages navigation between multiple onboarding screens
class OnboardingWrapper extends ConsumerStatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    ref.read(onboardingProvider.notifier).goToNextPage();
  }

  void _previousPage() {
    ref.read(onboardingProvider.notifier).goToPreviousPage();
  }

  Future<void> _completeOnboarding() async {
    // Submit onboarding preferences and mark as complete
    await ref.read(onboardingProvider.notifier).submitPreferences();

    // Navigate to home screen
    if (mounted) {
      context.go(RouteConfig.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(
      onboardingProvider.select((state) => state.currentPage),
    );

    // Listen to page changes and sync PageController
    ref.listen<int>(onboardingProvider.select((state) => state.currentPage), (
      previous,
      next,
    ) {
      if (_pageController.hasClients && previous != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Page view with onboarding screens
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (int page) {
              // Update provider if page changes manually
              if (page != currentPage) {
                if (page > currentPage) {
                  ref.read(onboardingProvider.notifier).goToNextPage();
                } else {
                  ref.read(onboardingProvider.notifier).goToPreviousPage();
                }
              }
            },
            children: [
              OnboardingScreen1(onNext: _nextPage),
              OnboardingScreen3(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreen5(onComplete: _completeOnboarding),
            ],
          ),
        ],
      ),
    );
  }
}
