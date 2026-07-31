import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

class MyPracticesStatsCard extends StatelessWidget {
  const MyPracticesStatsCard({
    super.key,
    required this.planCount,
    required this.chantCount,
    this.onTap,
  });

  final int planCount;
  final int chantCount;
  final VoidCallback? onTap;

  static const _borderRadius = 20.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(_borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.routine_title,
                        strutStyle: context.tibetanStrutStyle(22),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    _ArrowButton(onTap: onTap),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.home_overall_stats,
                  strutStyle: context.tibetanStrutStyle(14, compact: true),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: AppAssets.homeList,
                        count: planCount,
                        labelBuilder: l10n.home_plans_count,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: AppAssets.bookOpenText,
                        count: chantCount,
                        labelBuilder: l10n.home_recitation_count,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(AppAssets.arrowRight, color: AppColors.blue),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.count,
    required this.labelBuilder,
  });

  final IconData icon;
  final int count;
  final String Function(int count) labelBuilder;

  @override
  Widget build(BuildContext context) {
    const countFontSize = 22.0;
    const labelFontSize = 14.0;
    final countText = '$count';
    final fullText = labelBuilder(count);
    final baseStyle = DefaultTextStyle.of(
      context,
    ).style.copyWith(color: Colors.white, height: 1.2);
    final countStyle = baseStyle.copyWith(
      fontSize: countFontSize,
      fontWeight: FontWeight.w700,
    );
    final labelStyle = baseStyle.copyWith(
      fontSize: labelFontSize,
      fontWeight: FontWeight.w400,
    );

    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            strutStyle: context.tibetanStrutStyle(countFontSize),
            text: TextSpan(
              style: baseStyle,
              children: _styledStatSpans(
                fullText: withTibetanLineBreakOpportunities(fullText),
                countText: countText,
                countStyle: countStyle,
                labelStyle: labelStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<InlineSpan> _styledStatSpans({
  required String fullText,
  required String countText,
  required TextStyle countStyle,
  required TextStyle labelStyle,
}) {
  final countIndex = fullText.indexOf(countText);
  if (countIndex < 0) {
    return [TextSpan(text: fullText, style: labelStyle)];
  }

  final spans = <InlineSpan>[];
  if (countIndex > 0) {
    spans.add(
      TextSpan(text: fullText.substring(0, countIndex), style: labelStyle),
    );
  }
  spans.add(TextSpan(text: countText, style: countStyle));
  if (countIndex + countText.length < fullText.length) {
    spans.add(
      TextSpan(
        text: fullText.substring(countIndex + countText.length),
        style: labelStyle,
      ),
    );
  }
  return spans;
}
