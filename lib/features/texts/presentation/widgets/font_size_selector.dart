import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/texts/data/providers/font_size_notifier.dart';

class FontSizeSelector extends ConsumerWidget {
  const FontSizeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(fontSizeProvider);

    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final size in [12.0, 18.0, 24.0, 30.0, 40.0])
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: size,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              padding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Colors.grey.shade300,
              min: 10,
              max: 40,
              value: fontSize,
              label: '${fontSize.round()}',
              onChanged: (value) {
                ref.read(fontSizeProvider.notifier).setFontSize(value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('50%'),
                Text('110%'),
                Text('175%'),
                Text('235%'),
                Text('300%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
