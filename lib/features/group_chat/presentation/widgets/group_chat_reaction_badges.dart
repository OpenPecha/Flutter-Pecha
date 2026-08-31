import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';

/// Reaction summary painted inside the bubble, bottom-right.
///
/// At most [kChatBadgeEmojiLimit] distinct emoji are shown, busiest first,
/// followed by the total across all of them — so the badge never wraps and the
/// bubble keeps a stable height however many emoji accumulate.
class GroupChatReactionBadges extends StatelessWidget {
  const GroupChatReactionBadges({
    super.key,
    required this.reactions,
    required this.isSelf,
    required this.onShowAll,
  });

  final List<ChatMessageReactionDTO> reactions;
  final bool isSelf;

  /// Tapping the badge opens the reactions drawer, as in WhatsApp — it does
  /// not toggle. Reacting happens from the long-press pill or the drawer.
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final badge = chatBadgeReactions(reactions);
    if (badge.emoji.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countColor =
        isSelf
            ? AppColors.grey300
            : (isDark ? AppColors.textTertiaryDark : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: onShowAll,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final reaction in badge.emoji)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _Glyph(
                    emoji: reaction.emoji,
                    isMine: reaction.reactedByMe,
                    isDark: isDark,
                  ),
                ),
              const SizedBox(width: 2),
              Text(
                _count(context, badge.total),
                style: TextStyle(fontSize: 12, color: countColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _count(BuildContext context, int total) {
    final formatted = '$total';
    return context.isTibetanLocale ? toTibetanDigits(formatted) : formatted;
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({
    required this.emoji,
    required this.isMine,
    required this.isDark,
  });

  final String emoji;
  final bool isMine;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final glyph = Text(emoji, style: const TextStyle(fontSize: 13));
    if (!isMine) return glyph;

    // The mock only shows an unreacted badge; own reactions still need to read
    // as mine, so they get the same gold accent as the sender name.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.accentGold : AppColors.accentGoldDark)
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: glyph,
    );
  }
}
