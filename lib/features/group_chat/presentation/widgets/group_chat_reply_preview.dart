import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_quoted_message.dart';

/// The pinned quote above the composer while a reply is being written.
///
/// Lives in the same column as the composer, so it rides above the keyboard
/// with it rather than being covered by it.
class GroupChatReplyPreview extends StatelessWidget {
  const GroupChatReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
  });

  final ChatMessageDTO message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name =
        chatSenderDisplayName(
          messageName: message.senderName,
          senderEmail: message.senderEmail,
        ) ??
        context.l10n.group_chat_unknown_sender;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      color: isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.group_chat_replying_to(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: context.tibetanStrutStyle(12, compact: true),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                // The same quote block the bubble uses, so what is being
                // replied to looks identical before and after sending.
                GroupChatQuotedMessage(
                  parent: _asParent(message),
                  isPreview: true,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(AppAssets.x, size: 18),
            color: isDark ? AppColors.grey500 : AppColors.grey600,
            onPressed: onCancel,
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
        ],
      ),
    );
  }

  /// The message being replied to, shaped as the quote the server will echo
  /// back on the reply itself.
  static ChatMessageParentDTO _asParent(ChatMessageDTO message) {
    return ChatMessageParentDTO(
      id: message.id,
      senderId: message.senderId,
      senderEmail: message.senderEmail,
      senderName: message.senderName,
      senderAvatarUrl: message.senderAvatarUrl,
      body: message.body,
      createdAt: message.createdAt,
    );
  }
}
