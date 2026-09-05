import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Confirms deleting one of the member's own messages.
///
/// Only "delete for everyone" is offered. The API has no delete-for-me, so a
/// second option would have to be faked locally and would quietly disagree
/// with what everyone else sees.
///
/// Resolves true when the member confirms.
Future<bool> confirmChatMessageDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteMessageDialog(),
  );
  return confirmed ?? false;
}

class _DeleteMessageDialog extends StatelessWidget {
  const _DeleteMessageDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.group_chat_delete_title,
        strutStyle: context.tibetanStrutStyle(18, compact: true),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
        ),
      ),
      content: Text(
        l10n.group_chat_delete_confirm_body,
        strutStyle: context.tibetanStrutStyle(14),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.grey300 : AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            l10n.cancel,
            strutStyle: context.tibetanStrutStyle(14, compact: true),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.grey300 : AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            l10n.group_chat_delete_for_everyone,
            strutStyle: context.tibetanStrutStyle(14, compact: true),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
