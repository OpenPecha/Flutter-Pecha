import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_continue_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_question_title.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_radio_option.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Second onboarding screen: "How familiar are you with Buddhist principles?"
/// Based on Figma design node-id=380-293
class OnboardingScreen2 extends ConsumerWidget {
  const OnboardingScreen2({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const List<_QuestionOption> _options = [
    _QuestionOption(
      id: FamiliarityLevel.completelyNew,
      label: "I'm completely new",
    ),
    _QuestionOption(id: FamiliarityLevel.knowLittle, label: 'I know a little'),
    _QuestionOption(
      id: FamiliarityLevel.practicingBuddhist,
      label: 'I am a practicing Buddhist',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLevel = ref.watch(
      onboardingProvider.select((state) => state.preferences.familiarityLevel),
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
                title: 'How familiar are you \nwith Buddhist \nprinciples?',
              ),
              const SizedBox(height: 60),
              _buildOptions(ref, selectedLevel),
              const Spacer(),
              OnboardingContinueButton(
                onPressed: () => _handleContinue(ref),
                isEnabled: selectedLevel != null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(WidgetRef ref, String? selectedLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _options.map((option) {
            return OnboardingRadioOption(
              id: option.id,
              label: option.label,
              selectedId: selectedLevel,
              onSelect: (id) {
                ref.read(onboardingProvider.notifier).setFamiliarityLevel(id);
              },
            );
          }).toList(),
    );
  }

  void _handleContinue(WidgetRef ref) {
    final selectedLevel =
        ref.read(onboardingProvider).preferences.familiarityLevel;
    if (selectedLevel != null) {
      onNext();
    }
  }
}

class _QuestionOption {
  const _QuestionOption({required this.id, required this.label});

  final String id;
  final String label;
}
