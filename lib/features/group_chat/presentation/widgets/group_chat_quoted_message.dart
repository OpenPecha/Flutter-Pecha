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
    this.isPreview = false,
    this.onTap,
  });

  final ChatMessageParentDTO parent;

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

    // The quote carries the original author's colour on both the name and the
    // rule, so a reply says who it answers at a glance. Incoming and outgoing
    // bubbles share a fill, so only the theme decides the variant.
    final accent = chatSenderColor(
      seed: chatSenderSeed(
        senderId: parent.senderId,
        senderEmail: parent.senderEmail,
        name: parent.senderName,
      ),
      onDark: isDark,
    );
    // Dark needs both a stronger fill and a brighter body: 6% white over a
    // dark bubble is barely a panel at all, and the tertiary grey on top of it
    // left the quote looking switched off.
    final bodyColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final fill =
        isDark
            ? AppColors.surfaceWhite.withValues(alpha: 0.14)
            : AppColors.textPrimary.withValues(alpha: 0.04);

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
