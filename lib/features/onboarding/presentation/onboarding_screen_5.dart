import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Fifth onboarding screen: "You are All Setup"
/// Based on Figma design node-id=127-173
class OnboardingScreen5 extends ConsumerStatefulWidget {
  const OnboardingScreen5({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingScreen5> createState() => _OnboardingScreen5State();
}

class _OnboardingScreen5State extends ConsumerState<OnboardingScreen5>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _submitPreferencesAndNavigate();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  void _submitPreferencesAndNavigate() async {
    // Submit preferences to backend
    await ref.read(onboardingProvider.notifier).submitPreferences();

    // Wait for animation to complete, then navigate
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      onboardingProvider.select((state) => state.isLoading),
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompletionIcon(isLoading),
                    const SizedBox(height: 32),
                    _buildTitle(),
                    const SizedBox(height: 16),
                    _buildSubtitle(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionIcon(bool isLoading) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: Center(
        child:
            isLoading
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                )
                : const Icon(
                  Icons.check_circle,
                  size: 56,
                  color: AppColors.primary,
                ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'You are All Setup',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.544,
        color: AppColors.textPrimary,
        fontFamily: 'Instrument Serif',
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Welcome To WeBuddhist',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.442,
        color: Color(0xFF871C1C),
      ),
    );
  }
}
