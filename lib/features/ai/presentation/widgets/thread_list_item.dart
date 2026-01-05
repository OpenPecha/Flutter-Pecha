import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';

class ThreadListItem extends StatelessWidget {
  final ChatThreadSummary thread;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ThreadListItem({
    super.key,
    required this.thread,
    required this.isActive,
    required this.onTap,
    this.onDelete,
  });

  void _showContextMenu(BuildContext context, RenderBox renderBox) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get the position and size of the thread item
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Show blur overlay with context menu
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        pageBuilder: (context, animation, secondaryAnimation) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  // Full-width menu positioned above the thread item
                  Positioned(
                    left: position.dx + 16, // Position relative to thread item
                    top: position.dy - 50,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                        ), // Limit max width
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppColors.surfaceDark
                                  : AppColors.grey100,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete option
                            InkWell(
                              onTap: () => Navigator.of(context).pop('delete'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // Don't expand
                                  children: [
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 100), // Fixed spacing
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Highlight the selected thread item (make it visible through blur)
                  Positioned(
                    left: position.dx,
                    top: position.dy,
                    width: size.width,
                    height: size.height,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? AppColors.backgroundDark
                                  : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
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
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == 'delete' && onDelete != null) {
      onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () {
        if (onDelete != null) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          _showContextMenu(context, renderBox);
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color:
                isActive
                    ? (isDarkMode
                        ? AppColors.backgroundDark
                        : AppColors.grey100)
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
      ),
    );
  }
}
