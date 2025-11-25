import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionsSection extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Color dividerColor;
  final String slug;

  const CollectionsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dividerColor,
    required this.slug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final fontFamily = getFontFamily(locale.languageCode);
    final lineHeight = getLineHeight(locale.languageCode);
    final fontSize = locale.languageCode == 'bo' ? 26.0 : 22.0;
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: dividerColor, thickness: 3, height: 4),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: fontFamily,
              height: lineHeight,
              fontSize: fontSize.toDouble(),
            ),
          ),
          const SizedBox(height: 2),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16.0,
                height: lineHeight,
                fontFamily: fontFamily,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
