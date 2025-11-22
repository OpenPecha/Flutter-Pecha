import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActionOfTheDayCard extends ConsumerWidget {
  const ActionOfTheDayCard({
    super.key,
    required this.title,
    required this.duration,
    required this.iconWidget,
    required this.onTap,
  });
  final String title;
  final String duration;
  final Widget iconWidget;
  final Function() onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final fontFamily = getFontFamily(locale.languageCode);
    final lineHeight = getLineHeight(locale.languageCode);
    final titleFontSize = locale.languageCode == 'bo' ? 18.0 : 14.0;
    final subtitleFontSize = locale.languageCode == 'bo' ? 16.0 : 12.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 125,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: fontFamily,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w500,
                          fontFamily: fontFamily,
                          height: lineHeight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 122,
                height: double.infinity,
                child: iconWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
