import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_link_preview_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// One message row: self on the right in a dark bubble, everyone else on the
/// left in a white one with a gold sender name.
///
/// The avatar sits at the top of a same-sender run on the side the bubble is
/// on; later rows in the run keep a gutter so the block stays aligned.
class GroupChatMessageBubble extends StatelessWidget {
  const GroupChatMessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    required this.isRunStart,
    this.sender,
    this.selfAvatarUrl,
    this.selfDisplayName,
  });

  final ChatMessageDTO message;
  final bool isSelf;
  final bool isRunStart;
  final ChatSender? sender;

  /// Own avatar and name, which the sender directory cannot supply — the group
  /// people endpoint excludes the caller.
  final String? selfAvatarUrl;
  final String? selfDisplayName;

  static const double _avatarSize = 32;
  static const double _gutter = 40;
  static const double _maxWidthFactor = 0.76;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth = MediaQuery.sizeOf(context).width * _maxWidthFactor;
    final displayName =
        (isSelf
            ? (selfDisplayName ??
                chatSenderDisplayName(senderEmail: message.senderEmail))
            : chatSenderDisplayName(
              sender: sender,
              senderEmail: message.senderEmail,
            )) ??
        context.l10n.group_chat_unknown_sender;
    final avatar = _Avatar(
      avatarUrl: isSelf ? selfAvatarUrl : sender?.avatarUrl,
      displayName: displayName,
      isDark: isDark,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Row(
        mainAxisAlignment:
            isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSelf)
            isRunStart
                ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: avatar,
                )
                : const SizedBox(width: _gutter),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: _bubble(context, isDark, displayName),
            ),
          ),
          if (isSelf)
            isRunStart
                ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: avatar,
                )
                : const SizedBox(width: _gutter),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, bool isDark, String displayName) {
    final background =
        isSelf
            ? AppColors.grey900
            : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite);
    final textColor =
        isSelf
            ? AppColors.surfaceWhite
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final previewUrl = firstChatLinkUrl(message.body);
    // The tail corner is the one nearest the avatar, which sits at the top of
    // the run.
    const tail = Radius.circular(4);
    const round = Radius.circular(16);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: !isSelf && isRunStart ? tail : round,
          topRight: isSelf && isRunStart ? tail : round,
          bottomLeft: round,
          bottomRight: round,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSelf && isRunStart) ...[
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: context.tibetanStrutStyle(13, compact: true),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.accentGold : AppColors.accentGoldDark,
              ),
            ),
            const SizedBox(height: 2),
          ],
          ChatLinkText(
            body: message.body,
            textColor: textColor,
            isDark: isDark,
            isSelf: isSelf,
          ),
          if (previewUrl != null)
            GroupChatLinkPreviewCard(
              url: previewUrl,
              isSelf: isSelf,
              onOpen: _openUrl,
            ),
        ],
      ),
    );
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Message body with tappable links.
///
/// Stateful so the [TapGestureRecognizer]s it creates are disposed with the
/// row rather than leaking on every rebuild.
class ChatLinkText extends StatefulWidget {
  const ChatLinkText({
    super.key,
    required this.body,
    required this.textColor,
    required this.isDark,
    required this.isSelf,
  });

  final String body;
  final Color textColor;
  final bool isDark;
  final bool isSelf;

  @override
  State<ChatLinkText> createState() => _ChatLinkTextState();
}

class _ChatLinkTextState extends State<ChatLinkText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 15,
      height: 1.35,
      color: widget.textColor,
    );
    final links = findChatLinks(widget.body);

    if (links.isEmpty) {
      return Text(
        widget.body,
        strutStyle: context.tibetanStrutStyle(15),
        style: baseStyle,
      );
    }

    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final linkColor =
        widget.isSelf
            ? AppColors.surfaceWhite
            : (widget.isDark ? AppColors.brandblue : AppColors.blue);
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final link in links) {
      if (link.start > cursor) {
        spans.add(TextSpan(text: widget.body.substring(cursor, link.start)));
      }
      final recognizer =
          TapGestureRecognizer()
            ..onTap = () => GroupChatMessageBubble._openUrl(link.url);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: link.text,
          recognizer: recognizer,
          style: baseStyle.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
          ),
        ),
      );
      cursor = link.end;
    }
    if (cursor < widget.body.length) {
      spans.add(TextSpan(text: widget.body.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      strutStyle: context.tibetanStrutStyle(15),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.avatarUrl,
    required this.displayName,
    required this.isDark,
  });

  final String? avatarUrl;
  final String displayName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasUrl = url != null && url.isNotEmpty;

    return ClipOval(
      child: SizedBox(
        width: GroupChatMessageBubble._avatarSize,
        height: GroupChatMessageBubble._avatarSize,
        child:
            hasUrl
                ? CachedNetworkImageWidget(
                  key: ValueKey(url),
                  imageUrl: url,
                  width: GroupChatMessageBubble._avatarSize,
                  height: GroupChatMessageBubble._avatarSize,
                  fit: BoxFit.cover,
                  errorWidget: _initials(),
                )
                : _initials(),
      ),
    );
  }

  Widget _initials() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Center(
        child: Text(
          chatSenderInitials(displayName),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.grey500 : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}
