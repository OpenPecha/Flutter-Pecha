import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Chant-again and finish-session actions shown at the end of the reader text
/// when opened from a group accumulation with text content.
class GroupAccumulatorChantFooter extends StatelessWidget {
  const GroupAccumulatorChantFooter({
    super.key,
    required this.onChantAgain,
    required this.onFinishSession,
    this.isChantAgainEnabled = true,
  });

  final VoidCallback onChantAgain;
  final VoidCallback onFinishSession;
  final bool isChantAgainEnabled;

  static const _buttonHeight = 52.0;
  static const _borderRadius = 999.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          _ChantActionButton(
            label: l10n.group_accumulator_chant_again,
            backgroundColor:
                isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
            foregroundColor:
                isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
            onTap: isChantAgainEnabled ? onChantAgain : null,
          ),
          const SizedBox(height: 12),
          _ChantActionButton(
            label: l10n.group_accumulator_finish_session,
            backgroundColor:
                isDark ? AppColors.cardBorderDark : AppColors.grey100,
            foregroundColor:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            onTap: onFinishSession,
          ),
        ],
      ),
    );
  }
}

class _ChantActionButton extends StatelessWidget {
  const _ChantActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor.withValues(alpha: onTap == null ? 0.45 : 1),
      borderRadius: BorderRadius.circular(
        GroupAccumulatorChantFooter._borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: GroupAccumulatorChantFooter._buttonHeight,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
