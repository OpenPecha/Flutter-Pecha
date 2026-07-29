import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';

class TraditionsFormField extends StatelessWidget {
  const TraditionsFormField({
    super.key,
    required this.traditions,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
  });

  final List<UserTradition> traditions;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTap;
  final ValueChanged<UserTradition> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTraditions = traditions.isNotEmpty;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    final label = hasTraditions
        ? l10n.edit_profile_traditions
        : l10n.edit_profile_choose_traditions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: AppColors.grey500),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                suffixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(
                        AppAssets.caretRight,
                        size: 20,
                        color: AppColors.grey600,
                      ),
              ),
              child: hasTraditions
                  ? Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: traditions
                          .map((tradition) => _TraditionChip(
                                label: tradition.traditionName,
                                isDark: isDark,
                                onRemove: () => onRemove(tradition),
                              ))
                          .toList(),
                    )
                  : const SizedBox(height: 4),
            ),
          ),
        ),
      ],
    );
  }
}

class _TraditionChip extends StatelessWidget {
  const _TraditionChip({
    required this.label,
    required this.isDark,
    required this.onRemove,
  });

  final String label;
  final bool isDark;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 16,
                color: isDark ? AppColors.grey500 : AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
