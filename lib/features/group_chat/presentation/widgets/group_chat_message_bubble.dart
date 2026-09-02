import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_inline_format.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_blocks.dart';
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
    // One step apart rather than a hard contrast: the old charcoal outgoing
    // bubble was too heavy, and an identical fill left only the alignment to
    // tell the two apart. Outgoing is a warm tint of the incoming fill in
    // light, and one step lighter than it in dark.
    final background =
        isSelf
            ? (isDark ? AppColors.chipBackgroundDark : AppColors.goldAccent)
            : (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite);
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
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
            _body(context, textColor, isDark),
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
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A message with no markers stays a single [Text]; only one that needs
  /// block layout pays for it.
  Widget _body(BuildContext context, Color textColor, bool isDark) {
    if (!chatBodyNeedsBlocks(message.body)) {
      return ChatFormattedText(
        body: message.body,
        textColor: textColor,
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final block in parseChatMessageBlocks(message.body))
          _block(block, textColor, isDark),
      ],
    );
  }

  Widget _block(ChatTextBlock block, Color textColor, bool isDark) {
    final text = ChatFormattedText(
      body: block.text,
      textColor: textColor,
      isDark: isDark,
    );

    switch (block.kind) {
      case ChatBlockKind.paragraph:
        return text;

      case ChatBlockKind.bullet:
      case ChatBlockKind.numbered:
        // A fixed gutter, so a marked line that wraps hangs under its own text
        // rather than under the marker.
        return Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: block.kind == ChatBlockKind.bullet ? 16 : 22,
                child: Text(
                  block.marker ?? '\u2022',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ),
              Flexible(child: text),
            ],
          ),
        );

      case ChatBlockKind.quote:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Container(
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textSecondary,
                  width: 3,
                ),
              ),
            ),
            child: text,
          ),
        );

      case ChatBlockKind.code:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.surfaceWhite.withValues(alpha: 0.06)
                      : AppColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            // Literal on purpose: a fenced block is shown exactly as typed.
            child: Text(
              block.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: textColor,
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Courier New', 'Courier'],
              ),
            ),
          ),
        );
    }
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

/// Message body with tappable links and inline formatting.
///
/// Stateful so the [TapGestureRecognizer]s it creates are disposed with the
/// row rather than leaking on every rebuild.
class ChatFormattedText extends StatefulWidget {
  const ChatFormattedText({
    super.key,
    required this.body,
    required this.textColor,
    required this.isDark,
  });

  final String body;
  final Color textColor;
  final bool isDark;

  @override
  State<ChatFormattedText> createState() => _ChatFormattedTextState();
}

class _ChatFormattedTextState extends State<ChatFormattedText> {
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
    // Nothing to mark up: the cheapest path stays a plain Text.
    if (findChatLinks(widget.body).isEmpty &&
        !chatTextHasInlineMarkers(widget.body)) {
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

    final spans = <InlineSpan>[];
    for (final run in parseChatInlineRuns(widget.body)) {
      final style = baseStyle.copyWith(
        fontWeight: run.bold ? FontWeight.w700 : null,
        fontStyle: run.italic ? FontStyle.italic : null,
        decoration: run.strike ? TextDecoration.lineThrough : null,
        fontFamily: run.code ? 'monospace' : null,
        fontFamilyFallback: run.code ? const ['Courier New', 'Courier'] : null,
        backgroundColor:
            run.code
                ? (widget.isDark
                    ? AppColors.surfaceWhite.withValues(alpha: 0.08)
                    : AppColors.textPrimary.withValues(alpha: 0.06))
                : null,
      );
      if (run.code) {
        // Literal: a code span is never scanned for links.
        spans.add(TextSpan(text: run.text, style: style));
        continue;
      }
      _appendWithLinks(spans, run.text, style);
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      strutStyle: context.tibetanStrutStyle(15),
    );
  }

  /// Splits [text] on the URLs inside it, keeping [style] on the plain parts.
  void _appendWithLinks(List<InlineSpan> spans, String text, TextStyle style) {
    final links = findChatLinks(text);
    if (links.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return;
    }

    final linkColor = widget.isDark ? AppColors.brandblue : AppColors.blue;
    var cursor = 0;
    for (final link in links) {
      if (link.start > cursor) {
        spans.add(
          TextSpan(text: text.substring(cursor, link.start), style: style),
        );
      }
      final recognizer =
          TapGestureRecognizer()
            ..onTap = () => GroupChatMessageBubble._openUrl(link.url);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: link.text,
          recognizer: recognizer,
          style: style.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
          ),
        ),
      );
      cursor = link.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }
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
