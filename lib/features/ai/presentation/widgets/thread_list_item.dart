import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';

class ThreadListItem extends StatelessWidget {
  final ChatThreadSummary thread;
  final bool isActive;
  final VoidCallback onTap;

  const ThreadListItem({
    super.key,
    required this.thread,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          color:
              isActive
                  ? (isDarkMode ? AppColors.grey800 : AppColors.grey100)
                  : Colors.transparent,
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                thread.title,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDarkMode
                          ? AppColors.surfaceWhite
                          : AppColors.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
