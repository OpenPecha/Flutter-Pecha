import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';

/// Standardized AppBar for text feature screens
/// Provides consistent styling with back button, actions, and bottom border
class TextScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBottomBorder;
  final double toolbarHeight;
  final Color? borderColor;
  final Widget? title;

  const TextScreenAppBar({
    super.key,
    this.onBackPressed,
    this.actions,
    this.showBottomBorder = true,
    this.toolbarHeight = TextScreenConstants.appBarToolbarHeight,
    this.borderColor,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      elevation: TextScreenConstants.appBarElevation,
      scrolledUnderElevation: TextScreenConstants.appBarElevation,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      toolbarHeight: toolbarHeight,
      actions: actions,
      actionsPadding: TextScreenConstants.appBarActionsPadding,
      bottom:
          showBottomBorder
              ? PreferredSize(
                preferredSize: const Size.fromHeight(
                  TextScreenConstants.appBarBottomHeight,
                ),
                child: Container(
                  height: TextScreenConstants.appBarBottomHeight,
                  color: borderColor ?? TextScreenConstants.primaryBorderColor,
                ),
              )
              : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    toolbarHeight +
        (showBottomBorder ? TextScreenConstants.appBarBottomHeight : 0),
  );
}
