import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';

/// The quick reactions offered in the long-press pill — WhatsApp's six, in
/// WhatsApp's order.
///
/// Written as escapes on purpose: `'\u{2764}'` and `'\u{2764}\u{FE0F}'` are
/// different strings to the API, and a pasted ❤️ is easy to save without its
/// variation selector.
const kChatQuickReactions = <String>[
  '\u{1F44D}', // 👍 thumbs up
  '\u{2764}\u{FE0F}', // ❤️ red heart — U+2764 plus VS16
  '\u{1F602}', // 😂 joy
  '\u{1F62E}', // 😮 open mouth
  '\u{1F622}', // 😢 crying
  '\u{1F64F}', // 🙏 folded hands
];

/// Distinct emoji painted on a bubble before the count takes over.
const int kChatBadgeEmojiLimit = 3;

/// Recomputes `reactedByMe` for the viewer.
///
/// The flag on the wire is only viewer-specific on the REST response to our own
/// call — `reactions_updated` is one payload broadcast to every member, so its
/// flag cannot mean "me" for all of them. Email is matched first because the
/// app has no dependable copy of the backend UUID: storage holds the JWT `sub`
/// and `/users/info` returns no id.
List<ChatMessageReactionDTO> chatReactionsForViewer(
  List<ChatMessageReactionDTO> reactions, {
  String? currentUserId,
  String? currentUserEmail,
}) {
  final id = currentUserId?.trim() ?? '';
  final email = currentUserEmail?.trim().toLowerCase() ?? '';

  return reactions.map((reaction) {
    final mine = _isMine(reaction, id: id, email: email);
    if (mine == null || mine == reaction.reactedByMe) return reaction;
    return ChatMessageReactionDTO(
      emoji: reaction.emoji,
      count: reaction.count,
      reactedByMe: mine,
      userIds: reaction.userIds,
      users: reaction.users,
    );
  }).toList();
}

/// Null when neither identifier can decide, leaving the payload's own flag.
bool? _isMine(
  ChatMessageReactionDTO reaction, {
  required String id,
  required String email,
}) {
  if (email.isNotEmpty && reaction.users.isNotEmpty) {
    return reaction.users.any(
      (user) => (user.email ?? '').trim().toLowerCase() == email,
    );
  }
  if (id.isNotEmpty && reaction.userIds.isNotEmpty) {
    return reaction.userIds.any((userId) => userId.trim() == id);
  }
  return null;
}

/// The emoji this viewer has already reacted with, or null.
///
/// A member holds at most one reaction on a message (WhatsApp semantics), so
/// the first match is the answer.
String? currentChatReactionEmoji(List<ChatMessageReactionDTO> reactions) {
  for (final reaction in reactions) {
    if (reaction.reactedByMe) return reaction.emoji;
  }
  return null;
}

/// Every emoji this viewer holds, not just the first.
///
/// One is the norm, but a cleanup that failed leaves two on the server, and
/// the next burst has to know about both or the extra is never retried.
Set<String> ownChatReactionEmoji(List<ChatMessageReactionDTO> reactions) {
  return {
    for (final reaction in reactions)
      if (reaction.reactedByMe && reaction.count > 0) reaction.emoji,
  };
}

/// The optimistic local result of reacting with [emoji] while holding
/// [previousEmoji].
///
/// Passing the same value for both is the un-react case. Counts never go
/// negative, an entry at zero is dropped, and the viewer is never left holding
/// two reactions.
List<ChatMessageReactionDTO> toggleChatReaction(
  List<ChatMessageReactionDTO> reactions,
  String emoji, {
  String? previousEmoji,
}) {
  final removing = previousEmoji == emoji;
  final result = <ChatMessageReactionDTO>[];

  for (final reaction in reactions) {
    if (previousEmoji != null && reaction.emoji == previousEmoji) {
      final count = reaction.count - 1;
      if (count > 0) {
        result.add(
          ChatMessageReactionDTO(
            emoji: reaction.emoji,
            count: count,
            userIds: reaction.userIds,
            users: reaction.users,
          ),
        );
      }
      continue;
    }
    if (!removing && reaction.emoji == emoji) {
      result.add(
        ChatMessageReactionDTO(
          emoji: reaction.emoji,
          count: reaction.count + 1,
          reactedByMe: true,
          userIds: reaction.userIds,
          users: reaction.users,
        ),
      );
      continue;
    }
    result.add(reaction);
  }

  final alreadyPresent = result.any((reaction) => reaction.emoji == emoji);
  if (!removing && !alreadyPresent) {
    result.add(
      ChatMessageReactionDTO(emoji: emoji, count: 1, reactedByMe: true),
    );
  }

  return result;
}

/// What the bubble badge paints: the busiest emoji first, capped, plus the
/// total across **all** reactions so the count stays honest past the cap.
({List<ChatMessageReactionDTO> emoji, int total}) chatBadgeReactions(
  List<ChatMessageReactionDTO> reactions, {
  int max = kChatBadgeEmojiLimit,
}) {
  final ranked = [...reactions.where((reaction) => reaction.count > 0)]
    ..sort((a, b) => b.count.compareTo(a.count));
  final total = ranked.fold<int>(0, (sum, reaction) => sum + reaction.count);
  return (emoji: ranked.take(max).toList(), total: total);
}
