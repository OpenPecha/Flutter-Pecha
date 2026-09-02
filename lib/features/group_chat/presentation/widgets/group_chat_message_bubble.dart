import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_link_preview_card.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_quoted_message.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reaction_badges.dart';
import 'package:intl/intl.dart';
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
    this.selfAvatarUrl,
    this.selfDisplayName,
    this.onLongPress,
    this.isHighlighted = false,
    this.onShowReactions,
    this.onTapQuote,
  });

  final ChatMessageDTO message;
  final bool isSelf;
  final bool isRunStart;

  /// Own avatar and name from the session, used only for messages this API
  /// has not yet stamped with `sender_name` / `sender_avatar_url`.
  final String? selfAvatarUrl;
  final String? selfDisplayName;

  /// Opens the long-press menu. The thread measures the row itself, so the
  /// bubble only reports the gesture.
  final VoidCallback? onLongPress;

  /// Briefly tinted after a quote jumped to this message.
  final bool isHighlighted;
  final VoidCallback? onShowReactions;

  /// Scrolls to the quoted original when it is still on screen.
  final VoidCallback? onTapQuote;

  static const double _avatarSize = 32;

  /// Space kept under the bubble for the reaction badge. Less than the badge's
  /// own height, so the remainder overlaps the bubble's bottom edge.
  static const double _badgeReserve = 9;

  /// How far the badge is inset from the bubble's inner corner.
  static const double _badgeInset = 10;
  static const double _gutter = 40;
  static const double _maxWidthFactor = 0.76;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxWidth = MediaQuery.sizeOf(context).width * _maxWidthFactor;
    // Identity travels with the message, so there is nothing to wait for.
    final displayName =
        (isSelf
            ? (message.senderName ??
                selfDisplayName ??
                chatSenderDisplayName(senderEmail: message.senderEmail))
            : chatSenderDisplayName(
              messageName: message.senderName,
              senderEmail: message.senderEmail,
            )) ??
        context.l10n.group_chat_unknown_sender;
    final avatarUrl =
        message.senderAvatarUrl ?? (isSelf ? selfAvatarUrl : null);
    final avatar = _Avatar(
      avatarUrl: avatarUrl,
      displayName: displayName,
      isDark: isDark,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      // Dark needs both the brighter gold and more of it: a low-alpha tint
      // over a near-black background is almost no shift at all, where the same
      // alpha over the cream light background reads clearly.
      color:
          isHighlighted
              ? (isDark
                  ? AppColors.accentGold.withValues(alpha: 0.26)
                  : AppColors.accentGoldDark.withValues(alpha: 0.14))
              : Colors.transparent,
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    // Only reserve the strip when there is a badge to hang in
                    // it, so unreacted bubbles keep their spacing.
                    padding: EdgeInsets.only(
                      bottom: message.reactions.isEmpty ? 0 : _badgeReserve,
                    ),
                    child: GestureDetector(
                      onLongPress: onLongPress,
                      child: _bubble(context, isDark, displayName),
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      // The inner corner: bottom-right on an incoming bubble,
                      // bottom-left on an outgoing one.
                      left: isSelf ? _badgeInset : null,
                      right: isSelf ? null : _badgeInset,
                      child: GroupChatReactionBadges(
                        reactions: message.reactions,
                        isSelf: isSelf,
                        onShowAll: onShowReactions ?? () {},
                      ),
                    ),
                ],
              ),
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

  Widget _bubble(BuildContext context, bool isDark, String? displayName) {
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
      // IntrinsicWidth so the trailing time can sit against the right edge of
      // the text. An Align or a full-width Row would expand to the maxWidth
      // constraint instead, stretching every reacted bubble across the screen.
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSelf && isRunStart) ...[
              Text(
                displayName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                strutStyle: context.tibetanStrutStyle(13, compact: true),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: chatSenderColor(
                    seed: chatSenderSeed(
                      senderId: message.senderId,
                      senderEmail: message.senderEmail,
                      name: message.senderName,
                    ),
                    onDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
            if (message.parent != null)
              GroupChatQuotedMessage(
                parent: message.parent!,
                isSelf: isSelf,
                onTap: onTapQuote,
              ),
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
            const SizedBox(height: 2),
            Text(
              _timeLabel(context),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color:
                    isSelf
                        ? AppColors.grey500
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(BuildContext context) {
    final formatted = DateFormat.jm(
      intlFormatLocaleOf(context),
    ).format(message.createdAtLocal);
    return context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
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

  /// Null while the directory is still resolving — initials derived from the
  /// email would change once the real name lands.
  final String? displayName;
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
    final name = displayName;
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child:
          name == null
              ? const SizedBox.shrink()
              : Center(
                child: Text(
                  chatSenderInitials(name),
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
