import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Centered pill-style page indicator — active page is a wide capsule, inactive
/// pages are small circles, all inside a rounded track (see home poems section).
class PoemDotsIndicator extends StatelessWidget {
  const PoemDotsIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    this.backgroundColor,
    this.borderColor,
  });

  final int count;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final Color? backgroundColor;
  final Color? borderColor;

  static const double dotSize = 6;
  static const double activeDotWidth = 18;
  static const double gap = 5;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor ?? AppColors.grey100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < count; index++) ...[
              if (index > 0) const SizedBox(width: gap),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: index == currentIndex ? activeDotWidth : dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color:
                      index == currentIndex ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(dotSize / 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
