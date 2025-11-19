import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Reusable list item for text entries
/// Handles font family and size based on language
class TextListItem extends StatelessWidget {
  final String title;
  final String language;
  final VoidCallback onTap;
  final bool showDivider;

  const TextListItem({
    super.key,
    required this.title,
    required this.language,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider)
          const Divider(
            thickness: TextScreenConstants.thinDividerThickness,
            color: TextScreenConstants.sectionDividerColor,
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: getFontSize(language),
              fontFamily: getFontFamily(language),
            ),
          ),
          onTap: onTap,
        ),
      ],
    );
  }
}
