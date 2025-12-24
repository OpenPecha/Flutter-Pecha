import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  final String currentContent;

  const TypingIndicator({
    super.key,
    this.currentContent = '',
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sparkle icon (not in circle)
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
          ),
          const SizedBox(width: 8),

          // Content: Either streaming text or animated dots
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceVariantDark : AppColors.grey100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: widget.currentContent.isEmpty
                  ? _buildAnimatedDots(isDarkMode)
                  : Text(
                      widget.currentContent,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final value = (_controller.value - delay) % 1.0;
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: (isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary)
                      .withOpacity(opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

