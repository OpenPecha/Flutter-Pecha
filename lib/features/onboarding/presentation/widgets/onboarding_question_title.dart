import 'package:flutter/material.dart';

/// Reusable title widget for onboarding questionnaire screens
class OnboardingQuestionTitle extends StatelessWidget {
  const OnboardingQuestionTitle({super.key, required this.title, this.style});

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style:
          style ??
          const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.544,
            color: Color(0xFF020C1D),
            fontFamily: 'Inter',
          ),
    );
  }
}
