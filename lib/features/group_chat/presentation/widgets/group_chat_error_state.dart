import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Load failure with a retry, shared by the room lookup and the message list.
class GroupChatErrorState extends StatelessWidget {
  const GroupChatErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.group_chat_load_failed,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.group_chat_retry),
            ),
          ],
        ),
      ),
    );
  }
}
