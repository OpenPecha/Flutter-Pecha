import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_user_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const thumbsUp = '\u{1F44D}';
const heart = '\u{2764}\u{FE0F}';

ChatMessageDTO _message(String id, {String senderId = 'a'}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: senderId,
    senderEmail: '$senderId@example.com',
    body: 'body $id',
    createdAt: '2026-08-28T12:00:00Z',
  );
}

/// Serves a fixed newest-first history, sliced by skip/limit like the API.
class _FakeGroupChatRepository implements GroupChatRepository {
  _FakeGroupChatRepository({required this.history});

  List<ChatMessageDTO> history;
  Failure? listFailure;
  int listCallCount = 0;

  /// Reaction summaries handed back, in call order.
  List<List<ChatMessageReactionDTO>> reactionResponses = const [];
  Failure? reactionFailure;
  bool failFirstReaction = false;
  final List<String> reactionCalls = [];

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  }) async {
    listCallCount++;
    final failure = listFailure;
    if (failure != null) return Left(failure);
    final end = (skip + limit).clamp(0, history.length);
    final start = skip.clamp(0, history.length);
    return Right(
      ChatMessagesPage(
        messages: history.sublist(start, end),
        skip: skip,
        limit: limit,
        total: history.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async =>
      const Right(ChatRoomsPage(rooms: [], skip: 0, limit: 0, total: 0));

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      Left(const NotFoundFailure('not used'));

  @override
  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  }) async => Right(_message('sent'));

  @override
  Future<Either<Failure, ChatRoomMembersPage>> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  }) async => const Right(
    ChatRoomMembersPage(members: [], skip: 0, limit: 0, total: 0),
  );

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async =>
      const Right(unit);

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => _reaction('POST $emoji');

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => _reaction('DELETE $emoji');

  Either<Failure, List<ChatMessageReactionDTO>> _reaction(String call) {
    reactionCalls.add(call);
    if (failFirstReaction && reactionCalls.length == 1) {
      return const Left(NetworkFailure('offline'));
    }
    final failure = reactionFailure;
    if (failure != null) return Left(failure);
    final index = reactionCalls.length - 1;
    if (index < reactionResponses.length) {
      return Right(reactionResponses[index]);
    }
    return const Right([]);
  }
}

/// autoDispose tears the provider down the moment nothing listens, so tests
/// hold a subscription open for the life of the container.
GroupChatThreadNotifier _keepAlive(ProviderContainer container) {
  container.listen(groupChatThreadProvider('room-1'), (_, _) {});
  return container.read(groupChatThreadProvider('room-1').notifier);
}

/// Lets the constructor's `loadInitial` (and any pending fetch) settle.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeGroupChatRepository repository;
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [groupChatRepositoryProvider.overrideWithValue(repository)],
    );
  }

  tearDown(() => container.dispose());

  group('GroupChatThreadNotifier', () {
    test('loadInitial fills the newest page and reports more to come',
        () async {
      repository = _FakeGroupChatRepository(
        history: List.generate(50, (i) => _message('m$i')),
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.messages, hasLength(30));
      expect(notifier.state.messages.first.id, 'm0');
      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.total, 50);
    });

    test('loadMore appends older messages and stops at total', () async {
      repository = _FakeGroupChatRepository(
        history: List.generate(50, (i) => _message('m$i')),
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      await notifier.loadMore();

      expect(notifier.state.messages, hasLength(50));
      expect(notifier.state.messages.last.id, 'm49');
      expect(notifier.state.hasMore, isFalse);

      // Exhausted: a further request is not sent.
      final callsBefore = repository.listCallCount;
      await notifier.loadMore();
      expect(repository.listCallCount, callsBefore);
    });

    test('appendLive prepends and dedupes by id', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      notifier.appendLive(_message('m2'));
      expect(notifier.state.messages.map((m) => m.id).toList(), ['m2', 'm1']);

      // The socket echo of a message already held changes nothing.
      notifier.appendLive(_message('m2'));
      expect(notifier.state.messages, hasLength(2));
    });

    test('a REST send followed by its socket echo yields one row', () async {
      repository = _FakeGroupChatRepository(history: []);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      // The POST response is inserted directly...
      notifier.appendLive(_message('sent-1'));
      // ...then `message_created` echoes the same id back.
      notifier.appendLive(_message('sent-1'));

      expect(notifier.state.messages, hasLength(1));
      expect(notifier.state.total, 1);
    });

    test('loadInitial surfaces a failure and still marks the fetch settled',
        () async {
      repository = _FakeGroupChatRepository(history: []);
      repository.listFailure = const NetworkFailure('offline');
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.error, 'offline');
      expect(notifier.state.hasLoaded, isTrue);
      expect(notifier.state.messages, isEmpty);
    });

    test('refreshLatest merges what was missed without duplicating', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      // Two messages arrived while the socket was down.
      repository.history = [_message('m3'), _message('m2'), _message('m1')];
      await notifier.refreshLatest();

      expect(notifier.state.messages.map((m) => m.id).toList(), [
        'm3',
        'm2',
        'm1',
      ]);
    });
  });

  group('reactions', () {
    ChatMessageDTO reacted(String id, List<ChatMessageReactionDTO> reactions) {
      return _message(id).copyWith(reactions: reactions);
    }

    test('replaceReactions rewrites one message and leaves the rest', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
      ]);

      final byId = {for (final m in notifier.state.messages) m.id: m};
      expect(byId['m1']!.reactions.single.emoji, thumbsUp);
      expect(byId['m2']!.reactions, isEmpty);
    });

    test('replaceReactions ignores a message outside the window', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      notifier.replaceReactions('gone', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
      ]);

      expect(notifier.state.messages.single.reactions, isEmpty);
    });

    test('replaceReactions re-derives reactedByMe for this viewer', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // A broadcast flag that is about somebody else.
      notifier.replaceReactions(
        'm1',
        const [
          ChatMessageReactionDTO(
            emoji: thumbsUp,
            count: 1,
            reactedByMe: true,
            users: [
              ChatMessageReactionUserDTO(userId: 'u2', email: 'jack@e.com'),
            ],
          ),
        ],
        currentUserEmail: 'rena@example.com',
      );

      expect(notifier.state.messages.single.reactions.single.reactedByMe,
          isFalse);
    });

    test('toggleReaction posts and adopts the returned summary', () async {
      repository = _FakeGroupChatRepository(history: [_message('m1')]);
      repository.reactionResponses = const [
        [ChatMessageReactionDTO(emoji: thumbsUp, count: 4)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final failure = await notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
      );

      expect(failure, isNull);
      expect(repository.reactionCalls, ['POST $thumbsUp']);
      expect(notifier.state.messages.single.reactions.single.count, 4);
    });

    test('toggleReaction on my own emoji deletes it', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      await notifier.toggleReaction('m1', thumbsUp, roomIdForCall: 'room-1');

      expect(repository.reactionCalls, ['DELETE $thumbsUp']);
    });

    test('swapping posts the new emoji before deleting the old', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      await notifier.toggleReaction('m1', heart, roomIdForCall: 'room-1');

      // Post first, so the message never flickers through zero reactions.
      expect(repository.reactionCalls, ['POST $heart', 'DELETE $thumbsUp']);
    });

    test('a swap never shows both emoji, even mid-flight', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      // The POST response legitimately carries both: the DELETE has not run.
      repository.reactionResponses = const [
        [
          ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
          ChatMessageReactionDTO(emoji: heart, count: 1),
        ],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      // A broadcast arriving mid-swap carries the same two.
      final seen = <int>[];
      container.listen(groupChatThreadProvider('room-1'), (_, next) {
        final message = next.messages.firstWhere((m) => m.id == 'm1');
        seen.add(message.reactions.length);
      });

      await notifier.toggleReaction('m1', heart, roomIdForCall: 'room-1');

      expect(notifier.state.messages.single.reactions.single.emoji, heart);
      // Never two entries at any point the UI could have rendered.
      expect(seen, everyElement(lessThanOrEqualTo(1)));
    });

    test('a broadcast mid-swap is ignored', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: thumbsUp,
              count: 1,
              reactedByMe: true,
            ),
          ]),
        ],
      );
      repository.reactionResponses = const [
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final pending = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
      );
      // reactions_updated for the POST, before the DELETE lands.
      notifier.replaceReactions('m1', const [
        ChatMessageReactionDTO(emoji: thumbsUp, count: 1),
        ChatMessageReactionDTO(emoji: heart, count: 1),
      ]);
      expect(notifier.state.messages.single.reactions, hasLength(1));

      await pending;
      expect(notifier.state.messages.single.reactions.single.emoji, heart);
    });

    test('overlapping toggles do not undo the newer choice', () async {
      repository = _FakeGroupChatRepository(
        history: [reacted('m1', const [])],
      );
      // The first call fails; the second succeeds.
      repository.failFirstReaction = true;
      repository.reactionResponses = const [
        [],
        [ChatMessageReactionDTO(emoji: heart, count: 1, reactedByMe: true)],
        // The swap's trailing DELETE of the phantom thumbs-up.
        [ChatMessageReactionDTO(emoji: heart, count: 1, reactedByMe: true)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final first = notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
      );
      final second = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
      );
      await Future.wait([first, second]);

      // The superseded failure must not roll the newer heart away.
      final reactions = notifier.state.messages.single.reactions;
      expect(reactions.map((r) => r.emoji), [heart]);
    });

    test('a queued swap deletes what the server holds, not the phantom',
        () async {
      const prayer = '🙏';
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(
              emoji: prayer,
              count: 1,
              reactedByMe: true,
              users: [
                ChatMessageReactionUserDTO(
                  userId: 'u1',
                  email: 'rena@example.com',
                ),
              ],
            ),
          ]),
        ],
      );
      // The first POST fails, so the prayer is never dropped and stays on the
      // server while the local state has already moved on.
      repository.failFirstReaction = true;
      repository.reactionResponses = const [
        [],
        // POST heart: the server still holds the prayer too.
        [
          ChatMessageReactionDTO(
            emoji: prayer,
            count: 1,
            users: [
              ChatMessageReactionUserDTO(
                userId: 'u1',
                email: 'rena@example.com',
              ),
            ],
          ),
          ChatMessageReactionDTO(emoji: heart, count: 1),
        ],
        [ChatMessageReactionDTO(emoji: heart, count: 1)],
      ];
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final first = notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
        currentUserEmail: 'rena@example.com',
      );
      final second = notifier.toggleReaction(
        'm1',
        heart,
        roomIdForCall: 'room-1',
        currentUserEmail: 'rena@example.com',
      );
      await Future.wait([first, second]);

      // The prayer is what the server actually had — not the thumbs-up the
      // optimistic state showed.
      expect(repository.reactionCalls.last, 'DELETE $prayer');
      expect(
        notifier.state.messages.single.reactions.map((r) => r.emoji),
        [heart],
      );
    });

    test('refreshLatest updates reactions on messages already held', () async {
      repository = _FakeGroupChatRepository(
        history: [reacted('m1', const [])],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.messages.single.reactions, isEmpty);

      // A reaction landed while the socket was down.
      repository.history = [
        reacted('m1', const [
          ChatMessageReactionDTO(emoji: thumbsUp, count: 2),
        ]),
      ];
      await notifier.refreshLatest();

      expect(notifier.state.messages.single.reactions.single.count, 2);
    });

    test('refreshLatest derives reactedByMe for this viewer', () async {
      repository = _FakeGroupChatRepository(
        history: [reacted('m1', const [])],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [
        reacted('m1', const [
          ChatMessageReactionDTO(
            emoji: thumbsUp,
            count: 1,
            users: [
              ChatMessageReactionUserDTO(
                userId: 'u1',
                email: 'rena@example.com',
              ),
            ],
          ),
        ]),
      ];
      await notifier.refreshLatest(currentUserEmail: 'rena@example.com');

      expect(
        notifier.state.messages.single.reactions.single.reactedByMe,
        isTrue,
      );
    });

    test('a failed call rolls back to the previous reactions', () async {
      repository = _FakeGroupChatRepository(
        history: [
          reacted('m1', const [
            ChatMessageReactionDTO(emoji: thumbsUp, count: 2),
          ]),
        ],
      );
      repository.reactionFailure = const NetworkFailure('offline');
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      final failure = await notifier.toggleReaction(
        'm1',
        thumbsUp,
        roomIdForCall: 'room-1',
      );

      expect(failure, isA<NetworkFailure>());
      final reactions = notifier.state.messages.single.reactions;
      expect(reactions.single.count, 2);
      expect(reactions.single.reactedByMe, isFalse);
    });
  });

  group('refreshLatest gaps', () {
    test('restarts from the newest page when the gap cannot be stitched',
        () async {
      repository = _FakeGroupChatRepository(
        history: List.generate(40, (i) => _message('old$i')),
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.messages, hasLength(30));

      // 40 brand-new messages arrived while the socket was down: a full page
      // with nothing in common with what is held.
      repository.history = List.generate(40, (i) => _message('new$i'));
      await notifier.refreshLatest();

      final ids = notifier.state.messages.map((m) => m.id).toList();
      expect(ids, hasLength(30));
      // Nothing stale is stitched onto a non-contiguous page.
      expect(ids.every((id) => id.startsWith('new')), isTrue);
      // skip matches what is held, so loadMore walks back through the gap.
      expect(notifier.state.skip, 30);
      expect(notifier.state.hasMore, isTrue);
    });

    test('stitches normally when the page overlaps what is held', () async {
      repository = _FakeGroupChatRepository(
        history: [_message('m2'), _message('m1')],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);
      await _settle();

      repository.history = [_message('m3'), _message('m2'), _message('m1')];
      await notifier.refreshLatest();

      expect(notifier.state.messages.map((m) => m.id), ['m3', 'm2', 'm1']);
    });
  });

  group('ChatLinkPreviewCache', () {
    test('distinguishes a cached failure from an absent entry', () {
      final cache = ChatLinkPreviewCache();

      expect(cache.contains('https://a.org'), isFalse);
      cache.write('https://a.org', null);
      expect(cache.contains('https://a.org'), isTrue);
      expect(cache.read('https://a.org'), isNull);
    });

    test('evicts the least recently used entry past capacity', () {
      final cache = ChatLinkPreviewCache(capacity: 2);

      cache.write('a', const ChatLinkPreview(url: 'a', title: 'A'));
      cache.write('b', const ChatLinkPreview(url: 'b', title: 'B'));
      cache.read('a'); // 'a' becomes most recently used
      cache.write('c', const ChatLinkPreview(url: 'c', title: 'C'));

      expect(cache.contains('b'), isFalse);
      expect(cache.contains('a'), isTrue);
      expect(cache.contains('c'), isTrue);
    });
  });
}
