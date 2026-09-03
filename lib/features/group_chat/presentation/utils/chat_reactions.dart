import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_user_dto.dart';

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
///
/// Both channels are consulted, and a miss on one is not an answer. `user_ids`
/// is the field the API documents for this — "user_ids lets a client receiving
/// a shared broadcast (where reacted_by_me cannot be viewer-specific) work out
/// its own reacted state" — while `users` carries display identity and its
/// `email` is **nullable**. Returning `false` off an unmatched email, as this
/// once did, made a populated `users` list mask `user_ids` entirely: the badge
/// lost its own-reaction marker, [currentChatReactionEmoji] went null so the
/// same emoji re-added instead of un-reacting, and `_ownFromSummary` pruned
/// the tracked set so a swap never cleaned up the emoji it replaced.
bool? _isMine(
  ChatMessageReactionDTO reaction, {
  required String id,
  required String email,
}) {
  final canMatchId = id.isNotEmpty && reaction.userIds.isNotEmpty;
  if (canMatchId && reaction.userIds.any((userId) => userId.trim() == id)) {
    return true;
  }

  final emails = reaction.users
      .map((user) => (user.email ?? '').trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList();
  final canMatchEmail = email.isNotEmpty && emails.isNotEmpty;
  if (canMatchEmail && emails.contains(email)) return true;

  // Only now is "not mine" a real answer, and only if something could have
  // matched at all.
  return canMatchId || canMatchEmail ? false : null;
}

/// Whether [user] is the signed-in viewer, by either identifier.
bool isChatReactionViewer(
  ChatMessageReactionUserDTO user, {
  String? currentUserId,
  String? currentUserEmail,
}) {
  final id = currentUserId?.trim() ?? '';
  if (id.isNotEmpty && user.userId.trim() == id) return true;
  final email = currentUserEmail?.trim().toLowerCase() ?? '';
  if (email.isEmpty) return false;
  return (user.email ?? '').trim().toLowerCase() == email;
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
/// [viewerId] / [viewerEmail] keep the roster honest while the round trip is
/// in flight. The count and `reactedByMe` alone are not enough: the drawer
/// lists people out of `users`, so bumping a count without adding the viewer
/// showed "2" above a single name with no row to tap to remove, and
/// decrementing without removing them left them listed as a reactor.
List<ChatMessageReactionDTO> toggleChatReaction(
  List<ChatMessageReactionDTO> reactions,
  String emoji, {
  String? previousEmoji,
  String? viewerId,
  String? viewerEmail,
}) {
  final removing = previousEmoji == emoji;
  final id = viewerId?.trim() ?? '';
  final email = viewerEmail?.trim() ?? '';
  final result = <ChatMessageReactionDTO>[];

  for (final reaction in reactions) {
    if (previousEmoji != null && reaction.emoji == previousEmoji) {
      final count = reaction.count - 1;
      if (count > 0) {
        result.add(
          ChatMessageReactionDTO(
            emoji: reaction.emoji,
            count: count,
            userIds: _idsWithoutViewer(reaction.userIds, id),
            users: _usersWithoutViewer(reaction.users, id: id, email: email),
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
          userIds: _idsWithViewer(reaction.userIds, id),
          users: _usersWithViewer(reaction.users, id: id, email: email),
        ),
      );
      continue;
    }
    result.add(reaction);
  }

  final alreadyPresent = result.any((reaction) => reaction.emoji == emoji);
  if (!removing && !alreadyPresent) {
    result.add(
      ChatMessageReactionDTO(
        emoji: emoji,
        count: 1,
        reactedByMe: true,
        userIds: _idsWithViewer(const [], id),
        users: _usersWithViewer(const [], id: id, email: email),
      ),
    );
  }

  return result;
}

List<String> _idsWithoutViewer(List<String> ids, String id) {
  if (id.isEmpty) return ids;
  return ids.where((value) => value.trim() != id).toList();
}

List<String> _idsWithViewer(List<String> ids, String id) {
  if (id.isEmpty || ids.any((value) => value.trim() == id)) return ids;
  return [...ids, id];
}

List<ChatMessageReactionUserDTO> _usersWithoutViewer(
  List<ChatMessageReactionUserDTO> users, {
  required String id,
  required String email,
}) {
  if (id.isEmpty && email.isEmpty) return users;
  return users
      .where(
        (user) => !isChatReactionViewer(
          user,
          currentUserId: id,
          currentUserEmail: email,
        ),
      )
      .toList();
}

List<ChatMessageReactionUserDTO> _usersWithViewer(
  List<ChatMessageReactionUserDTO> users, {
  required String id,
  required String email,
}) {
  // Nothing to add them under: the drawer falls back to its own "reacted by
  // me" row for a summary that names nobody.
  if (id.isEmpty && email.isEmpty) return users;
  final present = users.any(
    (user) =>
        isChatReactionViewer(user, currentUserId: id, currentUserEmail: email),
  );
  if (present) return users;
  return [
    ...users,
    ChatMessageReactionUserDTO(
      userId: id,
      email: email.isEmpty ? null : email,
    ),
  ];
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
