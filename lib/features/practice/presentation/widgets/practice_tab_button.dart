import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

enum PracticeActionButtonVariant { filled, outlined }

class PracticeTabButton extends StatelessWidget {
  const PracticeTabButton({
    super.key,
    required this.label,
    required this.variant,
    required this.onTap,
    this.icon,
    this.backgroundColor,
  });

  final String label;
  final PracticeActionButtonVariant variant;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? backgroundColor;

  static const _borderRadius = 12.0;
  static const _height = 44.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFilled = variant == PracticeActionButtonVariant.filled;
    final foregroundColor = isFilled ? Colors.white : AppColors.textPrimary;
    final backgroundColor =
        isDark ? AppColors.cardBackgroundDark : Colors.white;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return Material(
      color: isFilled ? (this.backgroundColor ?? AppColors.blue) : backgroundColor,
      borderRadius: BorderRadius.circular(_borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_borderRadius),
        child: Ink(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            border: isFilled ? null : Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isDark ? AppColors.textPrimaryDark : foregroundColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
