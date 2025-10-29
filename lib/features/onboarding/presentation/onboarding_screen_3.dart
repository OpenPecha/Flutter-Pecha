import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_continue_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_question_title.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_radio_option.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Third onboarding screen: "In which language would you like to access core texts?"
/// Based on Figma design node-id=127-166
class OnboardingScreen3 extends ConsumerWidget {
  const OnboardingScreen3({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const List<_LanguageOption> _languages = [
    _LanguageOption(id: PreferredLanguage.tibetan, label: 'Tibetan'),
    _LanguageOption(id: PreferredLanguage.english, label: 'English'),
    _LanguageOption(id: PreferredLanguage.sanskrit, label: 'Sanskrit'),
    _LanguageOption(id: PreferredLanguage.chinese, label: 'Chinese'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(
      onboardingProvider.select((state) => state.preferences.preferredLanguage),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              OnboardingBackButton(onBack: onBack),
              const SizedBox(height: 40),
              const OnboardingQuestionTitle(
                title:
                    'In which language \nwould you like to \naccess core texts?',
              ),
              const SizedBox(height: 60),
              _buildLanguageOptions(ref, selectedLanguage),
              const Spacer(),
              OnboardingContinueButton(
                onPressed: () => _handleContinue(ref),
                isEnabled: selectedLanguage != null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOptions(WidgetRef ref, String? selectedLanguage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _languages.map((language) {
            return OnboardingRadioOption(
              id: language.id,
              label: language.label,
              selectedId: selectedLanguage,
              onSelect: (id) {
                ref.read(onboardingProvider.notifier).setPreferredLanguage(id);
              },
            );
          }).toList(),
    );
  }

  void _handleContinue(WidgetRef ref) {
    final selectedLanguage =
        ref.read(onboardingProvider).preferences.preferredLanguage;
    if (selectedLanguage != null) {
      onNext();
    }
  }
}

class _LanguageOption {
  const _LanguageOption({required this.id, required this.label});

  final String id;
  final String label;
}
