import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

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
  Future<Either<Failure, ChatPeoplePage>> listGroupPeople(
    String groupId, {
    int skip = 0,
    int limit = 100,
  }) async =>
      const Right(ChatPeoplePage(people: [], skip: 0, limit: 0, total: 0));

  @override
  Future<Either<Failure, Unit>> markRoomRead(String roomId) async =>
      const Right(unit);
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
