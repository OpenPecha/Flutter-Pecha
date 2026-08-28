import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Message composer pinned to the bottom of the chat.
///
/// Geometry follows the connect comment composer: a pill field with a circular
/// send button, padded past the keyboard so the screen itself does not resize.
class GroupChatComposer extends StatelessWidget {
  const GroupChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.isSending,
    required this.onSubmit,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isSending;
  final VoidCallback onSubmit;
  final bool enabled;

  static const double _fieldHeight = 44;
  static const double _sendButtonSize = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafePadding = MediaQuery.viewPaddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        keyboardInset > 0 ? keyboardInset + 8 : bottomSafePadding + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _MessageField(
              controller: controller,
              focusNode: focusNode,
              isDark: isDark,
              hintText: hintText,
              enabled: enabled,
              onSubmit: onSubmit,
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSend =
                  enabled && value.text.trim().isNotEmpty && !isSending;
              return _SendButton(
                canSend: canSend,
                isSending: isSending,
                isDark: isDark,
                onPressed: canSend ? onSubmit : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MessageField extends StatelessWidget {
  const _MessageField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.hintText,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final String hintText;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;
    const radius = GroupChatComposer._fieldHeight / 2;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) {
        if (enabled) onSubmit();
      },
      style: TextStyle(
        fontSize: 15,
        height: 1.2,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 15,
          height: 1.2,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: fillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: isDark ? AppColors.grey600 : AppColors.grey400,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.canSend,
    required this.isSending,
    required this.isDark,
    required this.onPressed,
  });

  final bool canSend;
  final bool isSending;
  final bool isDark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        canSend
            ? (isDark ? AppColors.grey600 : AppColors.grey800)
            : (isDark ? AppColors.grey800 : AppColors.grey300);

    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: GroupChatComposer._sendButtonSize,
          height: GroupChatComposer._sendButtonSize,
          child: Center(
            child:
                isSending
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.surfaceWhite,
                      ),
                    )
                    : Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color:
                          canSend
                              ? AppColors.surfaceWhite
                              : (isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.surfaceWhite),
                    ),
          ),
        ),
      ),
    );
  }
}
