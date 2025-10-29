import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_screen_1.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_screen_2.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_screen_3.dart';
import 'package:flutter_pecha/features/onboarding/presentation/onboarding_screen_4.dart';
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
  final int _totalPages = 5;

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

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    context.go(RouteConfig.login);
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
              OnboardingScreen2(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreen3(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreen4(onNext: _nextPage, onBack: _previousPage),
              OnboardingScreen5(onComplete: _completeOnboarding),
            ],
          ),
          // Skip button (top right) - only show on first 4 screens
          if (currentPage < _totalPages - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
