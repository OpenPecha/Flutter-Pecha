import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable list item for text entries
/// Handles font family and size based on language
class TextListItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final fontFamily = getFontFamily(locale.languageCode);
    final lineHeight = getLineHeight(locale.languageCode);
    final fontSize = locale.languageCode == 'bo' ? 26.0 : 22.0;

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
              fontSize: fontSize,
              fontFamily: fontFamily,
              height: lineHeight,
            ),
          ),
          onTap: onTap,
        ),
      ],
    );
  }
}
