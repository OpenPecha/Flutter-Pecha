import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';

/// The quoted original, shown above the body of a reply.
///
/// Used both inside a bubble and — via [isPreview] — in the bar above the
/// composer while a reply is being written.
class GroupChatQuotedMessage extends StatelessWidget {
  const GroupChatQuotedMessage({
    super.key,
    required this.parent,
    this.isSelf = false,
    this.isPreview = false,
    this.onTap,
  });

  final ChatMessageParentDTO parent;

  /// Which bubble fill this sits on, which decides the tint and text colours.
  final bool isSelf;

  /// Preview mode sits on the page background rather than inside a bubble.
  final bool isPreview;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name =
        chatSenderDisplayName(
          messageName: parent.senderName,
          senderEmail: parent.senderEmail,
        ) ??
        context.l10n.group_chat_unknown_sender;

    final onDarkFill = isSelf && !isPreview;
    final accent =
        onDarkFill
            ? AppColors.surfaceWhite
            : (isDark ? AppColors.accentGold : AppColors.accentGoldDark);
    final bodyColor =
        onDarkFill
            ? AppColors.grey300
            : (isDark ? AppColors.textTertiaryDark : AppColors.textSecondary);
    final fill =
        onDarkFill
            ? AppColors.surfaceWhite.withValues(alpha: 0.12)
            : (isDark
                ? AppColors.surfaceWhite.withValues(alpha: 0.06)
                : AppColors.textPrimary.withValues(alpha: 0.04));

    return Padding(
      padding: EdgeInsets.only(bottom: isPreview ? 0 : 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(12, compact: true),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                parent.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(13),
                style: TextStyle(fontSize: 13, color: bodyColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
