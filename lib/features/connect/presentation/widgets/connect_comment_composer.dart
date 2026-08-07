import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class ConnectCommentComposer extends StatelessWidget {
  const ConnectCommentComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onSubmit,
    this.replyHandle,
    this.onClearReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final String? replyHandle;
  final VoidCallback? onClearReply;

  static const double _fieldHeight = 44;
  static const double _sendButtonSize = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyHandle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.connect_comment_replying_to(replyHandle!),
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppAssets.x, size: 18),
                    onPressed: onClearReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _CommentTextField(
                controller: controller,
                focusNode: focusNode,
                isDark: isDark,
                hintText:
                    replyHandle == null
                        ? l10n.connect_comment_hint
                        : l10n.connect_comment_reply_hint,
                onSubmit: onSubmit,
              )),
              const SizedBox(width: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend =
                      value.text.trim().isNotEmpty && !isSubmitting;
                  return _SendButton(
                    canSend: canSend,
                    isSubmitting: isSubmitting,
                    isDark: isDark,
                    onPressed: canSend ? onSubmit : null,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentTextField extends StatelessWidget {
  const _CommentTextField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.hintText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final String hintText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSubmit(),
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
          color:
              isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: fillColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConnectCommentComposer._fieldHeight / 2),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConnectCommentComposer._fieldHeight / 2),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ConnectCommentComposer._fieldHeight / 2),
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
    required this.isSubmitting,
    required this.isDark,
    required this.onPressed,
  });

  final bool canSend;
  final bool isSubmitting;
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
          width: ConnectCommentComposer._sendButtonSize,
          height: ConnectCommentComposer._sendButtonSize,
          child: Center(
            child:
                isSubmitting
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
