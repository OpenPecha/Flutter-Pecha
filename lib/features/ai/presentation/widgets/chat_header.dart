import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback? onNewChat;
  final VoidCallback? onMenuPressed;

  const ChatHeader({
    super.key,
    this.onNewChat,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onMenuPressed,
            icon: Icon(
              Icons.menu_sharp,
              color: isDarkMode ? AppColors.surfaceWhite : AppColors.cardBorderDark,
            ),
            tooltip: 'Chat History',
          ),
          Text(
            'Buddhist AI Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
            ),
          ),
          if (onNewChat != null)
            IconButton(
              onPressed: onNewChat,
              icon: Icon(
                Icons.add,
                color: isDarkMode ? AppColors.surfaceWhite : AppColors.cardBorderDark,
              ),
              tooltip: 'New Chat',
            ),
        ],
      ),
    );
  }
}
