import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

const _thumbsUp = '\u{1F44D}';
const _heart = '\u{2764}\u{FE0F}';
const _joy = '\u{1F602}';

ChatMessageReactionDTO _reaction(
  String emoji, {
  int count = 1,
  bool reactedByMe = false,
  List<String> userIds = const [],
  List<ChatMessageReactionUserDTO> users = const [],
}) {
  return ChatMessageReactionDTO(
    emoji: emoji,
    count: count,
    reactedByMe: reactedByMe,
    userIds: userIds,
    users: users,
  );
}

void main() {
  group('kChatQuickReactions', () {
    test('is WhatsApp six, with the heart carrying its variation selector', () {
      expect(kChatQuickReactions, hasLength(6));
      expect(kChatQuickReactions.first, _thumbsUp);
      expect(kChatQuickReactions[1], _heart);
      // A bare U+2764 is a different string to the DELETE path.
      expect(kChatQuickReactions[1], isNot('\u{2764}'));
    });
  });

  group('chatReactionsForViewer', () {
    test('marks a reaction mine when my email is among the users', () {
      final resolved = chatReactionsForViewer(
        [
          _reaction(
            _thumbsUp,
            count: 2,
            users: const [
              ChatMessageReactionUserDTO(
                userId: 'u1',
                email: 'Rena@Example.com',
              ),
              ChatMessageReactionUserDTO(userId: 'u2', email: 'jack@e.com'),
            ],
          ),
        ],
        currentUserEmail: 'rena@example.com',
      );

      expect(resolved.single.reactedByMe, isTrue);
    });

    test('clears a broadcast flag that is not about me', () {
      // reactions_updated is one payload for every member, so its
      // reacted_by_me cannot mean "me" for all of them.
      final resolved = chatReactionsForViewer(
        [
          _reaction(
            _thumbsUp,
            count: 1,
            reactedByMe: true,
            users: const [
              ChatMessageReactionUserDTO(userId: 'u2', email: 'jack@e.com'),
            ],
          ),
        ],
        currentUserEmail: 'rena@example.com',
      );

      expect(resolved.single.reactedByMe, isFalse);
    });

    test('falls back to user_ids when no email is known', () {
      final resolved = chatReactionsForViewer(
        [
          _reaction(_thumbsUp, count: 1, userIds: const ['u1', 'u2']),
        ],
        currentUserId: 'u1',
      );

      expect(resolved.single.reactedByMe, isTrue);
    });

    test('keeps the payload flag when neither identifier can decide', () {
      final resolved = chatReactionsForViewer([
        _reaction(_thumbsUp, count: 1, reactedByMe: true),
      ], currentUserEmail: 'rena@example.com');

      expect(resolved.single.reactedByMe, isTrue);
    });
  });

  group('currentChatReactionEmoji', () {
    test('returns the emoji I hold', () {
      expect(
        currentChatReactionEmoji([
          _reaction(_thumbsUp),
          _reaction(_heart, reactedByMe: true),
        ]),
        _heart,
      );
    });

    test('returns null when none is mine', () {
      expect(currentChatReactionEmoji([_reaction(_thumbsUp)]), isNull);
    });
  });

  group('toggleChatReaction', () {
    test('adds a first reaction', () {
      final result = toggleChatReaction(const [], _thumbsUp);

      expect(result.single.emoji, _thumbsUp);
      expect(result.single.count, 1);
      expect(result.single.reactedByMe, isTrue);
    });

    test('joins an emoji someone else already used', () {
      final result = toggleChatReaction([
        _reaction(_thumbsUp, count: 3),
      ], _thumbsUp);

      expect(result.single.count, 4);
      expect(result.single.reactedByMe, isTrue);
    });

    test('un-reacting drops the entry at zero', () {
      final result = toggleChatReaction(
        [_reaction(_thumbsUp, count: 1, reactedByMe: true)],
        _thumbsUp,
        previousEmoji: _thumbsUp,
      );

      expect(result, isEmpty);
    });

    test('un-reacting leaves other people behind', () {
      final result = toggleChatReaction(
        [_reaction(_thumbsUp, count: 3, reactedByMe: true)],
        _thumbsUp,
        previousEmoji: _thumbsUp,
      );

      expect(result.single.count, 2);
      expect(result.single.reactedByMe, isFalse);
    });

    test('swapping moves my vote and never leaves two mine', () {
      final result = toggleChatReaction(
        [
          _reaction(_thumbsUp, count: 2, reactedByMe: true),
          _reaction(_heart, count: 1),
        ],
        _heart,
        previousEmoji: _thumbsUp,
      );

      final byEmoji = {for (final r in result) r.emoji: r};
      expect(byEmoji[_thumbsUp]!.count, 1);
      expect(byEmoji[_thumbsUp]!.reactedByMe, isFalse);
      expect(byEmoji[_heart]!.count, 2);
      expect(byEmoji[_heart]!.reactedByMe, isTrue);
      expect(result.where((r) => r.reactedByMe), hasLength(1));
    });

    test('swapping away from an emoji only I used removes it', () {
      final result = toggleChatReaction(
        [_reaction(_thumbsUp, count: 1, reactedByMe: true)],
        _heart,
        previousEmoji: _thumbsUp,
      );

      expect(result.map((r) => r.emoji), [_heart]);
    });
  });

  group('chatBadgeReactions', () {
    test('orders by count and caps the distinct emoji', () {
      final badge = chatBadgeReactions([
        _reaction(_thumbsUp, count: 2),
        _reaction(_heart, count: 5),
        _reaction(_joy, count: 1),
        _reaction('\u{1F622}', count: 4),
      ]);

      expect(badge.emoji.map((r) => r.emoji), [
        _heart,
        '\u{1F622}',
        _thumbsUp,
      ]);
      // The total counts the emoji beyond the cap, so the number stays honest.
      expect(badge.total, 12);
    });

    test('drops empty entries and reports nothing to paint', () {
      final badge = chatBadgeReactions([_reaction(_thumbsUp, count: 0)]);

      expect(badge.emoji, isEmpty);
      expect(badge.total, 0);
    });
  });
}
