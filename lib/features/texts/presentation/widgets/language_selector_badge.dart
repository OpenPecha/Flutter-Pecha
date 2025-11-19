import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';

/// Language selector badge widget
/// Displays current language with icon in a styled badge
class LanguageSelectorBadge extends StatelessWidget {
  final String language;
  final VoidCallback onTap;

  const LanguageSelectorBadge({
    super.key,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: TextScreenConstants.languageBadgePadding,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            TextScreenConstants.languageBadgeBorderRadius,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.language,
              size: TextScreenConstants.languageIconSize,
            ),
            const SizedBox(width: 4),
            Text(
              language.toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
