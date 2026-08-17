import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';

/// Dialog for adding mala rounds completed outside the app.
///
/// Returns the selected round count, or `null` when dismissed.
Future<int?> showAddMalaRoundsDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _AddMalaRoundsDialog(),
  );
}

class _AddMalaRoundsDialog extends StatefulWidget {
  const _AddMalaRoundsDialog();

  @override
  State<_AddMalaRoundsDialog> createState() => _AddMalaRoundsDialogState();
}

class _AddMalaRoundsDialogState extends State<_AddMalaRoundsDialog> {
  static const _maxRounds = 9;

  int _rounds = 0;

  void _decrement() {
    if (_rounds <= 0) return;
    HapticFeedback.selectionClick();
    setState(() => _rounds--);
  }

  void _increment() {
    if (_rounds >= _maxRounds) return;
    HapticFeedback.selectionClick();
    setState(() => _rounds++);
  }

  void _confirm() {
    if (_rounds <= 0) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_rounds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.goldLight;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mala_add_rounds_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mala_add_rounds_message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundStepButton(
                  icon: AppAssets.minusCircle,
                  onPressed: _rounds > 0 ? _decrement : null,
                ),
                const SizedBox(width: 20),
                Container(
                  width: 72,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.cardBorderDark : AppColors.grey300,
                    ),
                  ),
                  child: Text(
                    context.isTibetanLocale
                        ? toTibetanDigits(_rounds)
                        : '$_rounds',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _RoundStepButton(
                  icon: AppAssets.plusCircle,
                  onPressed: _rounds < _maxRounds ? _increment : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _rounds > 0 ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.textPrimaryDark : Colors.black,
                foregroundColor: isDark ? AppColors.textPrimary : Colors.white,
                disabledBackgroundColor:
                    isDark ? AppColors.grey600 : AppColors.grey300,
                disabledForegroundColor:
                    isDark ? AppColors.grey500 : AppColors.grey600,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                l10n.ai_confirm,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      _rounds > 0
                          ? (isDark ? AppColors.textPrimary : Colors.white)
                          : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final color = enabled ? theme.colorScheme.onSurface : AppColors.grey400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Icon(icon, size: 40, color: color),
      ),
    );
  }
}
