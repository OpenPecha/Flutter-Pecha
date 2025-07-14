import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActionOfTheDayCard extends ConsumerWidget {
  const ActionOfTheDayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    this.isSpace = false,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final bool isSpace;
  final Function() onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [iconWidget, if (isSpace) const SizedBox(height: 16)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
