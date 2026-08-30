import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Shown in a joined room that has no messages yet.
class GroupChatEmptyState extends StatelessWidget {
  const GroupChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final bodyColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppAssets.usersThree,
              size: 40,
              color: isDark ? AppColors.grey600 : AppColors.grey400,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.group_chat_empty_title,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(16, compact: true),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.group_chat_empty_body,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(fontSize: 14, color: bodyColor),
            ),
          ],
        ),
      ),
    );
  }
}
