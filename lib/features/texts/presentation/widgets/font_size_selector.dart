import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_notifier.dart';

class FontSizeSelector extends ConsumerWidget {
  const FontSizeSelector({super.key, required this.language});
  final String language;

  // Base font size (100% = 16px)
  double get baseFontSize => language == 'bo' ? 26.0 : 22.0;

  // Industry standard font size percentages
  static const List<double> fontSizePercentages = [100, 150, 200, 250];

  // Convert percentage to actual font size
  double percentageToFontSize(double percentage) {
    return baseFontSize * (percentage / 100);
  }

  // Convert font size to percentage
  double fontSizeToPercentage(double fontSize) {
    return (fontSize / baseFontSize) * 100;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);
    final currentPercentage = fontSizeToPercentage(fontSize);

    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Visual representation of font sizes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final percentage in fontSizePercentages)
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: percentageToFontSize(percentage),
                      fontWeight: FontWeight.bold,
                      color:
                          (currentPercentage - percentage).abs() < 1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Slider with discrete steps
            Slider(
              padding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.grey.shade300,
              min: fontSizePercentages.first,
              max: fontSizePercentages.last,
              divisions: fontSizePercentages.length - 1,
              value: currentPercentage.clamp(
                fontSizePercentages.first,
                fontSizePercentages.last,
              ),
              label: '${currentPercentage.round()}%',
              onChanged: (value) {
                // Snap to nearest percentage
                final snappedPercentage = fontSizePercentages.reduce(
                  (prev, curr) =>
                      (curr - value).abs() < (prev - value).abs() ? curr : prev,
                );
                ref
                    .read(fontSizeProvider.notifier)
                    .setFontSize(percentageToFontSize(snappedPercentage));
              },
            ),
            const SizedBox(height: 16),
            // Percentage labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final percentage in fontSizePercentages)
                  Text(
                    '${percentage.round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          (currentPercentage - percentage).abs() < 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          (currentPercentage - percentage).abs() < 1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
