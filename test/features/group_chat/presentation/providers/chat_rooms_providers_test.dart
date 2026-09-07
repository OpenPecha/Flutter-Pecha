import 'dart:async';

import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/user_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/state/user_state.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/chat_rooms_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

ChatRoomDTO _group(int i, {int unreadCount = 0}) {
  return ChatRoomDTO(
    id: 'group-room-$i',
    createdBy: 'u9',
    groupId: 'group-$i',
    kind: 'group',
    name: 'Group $i',
    memberCount: 3,
    updatedAt: '2026-09-01T10:00:00Z',
    unreadCount: unreadCount,
  );
}

ChatRoomDTO _direct(int i) {
  return ChatRoomDTO(
    id: 'direct-room-$i',
    createdBy: 'u9',
    kind: 'direct',
    name: 'Direct $i',
    memberCount: 2,
    updatedAt: '2026-09-01T10:00:00Z',
  );
}

/// Serves a fixed rooms list, sliced by skip/limit like the API.
class _FakeGroupChatRepository implements GroupChatRepository {
  _FakeGroupChatRepository({required this.rooms});

  List<ChatRoomDTO> rooms;
  Failure? listFailure;

  /// Fails only the call with this 1-based index, then clears itself.
  int? failCall;
  int listCallCount = 0;

  /// Holds the next list call until completed, so a later one can overtake it.
  Completer<void>? holdNextList;

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async {
    listCallCount++;
    final hold = holdNextList;
    holdNextList = null;
    if (hold != null) await hold.future;
    if (failCall == listCallCount) {
      failCall = null;
      return const Left(NetworkFailure('offline'));
    }
    final failure = listFailure;
    if (failure != null) return Left(failure);
    final end = (skip + limit).clamp(0, rooms.length);
    final start = skip.clamp(0, rooms.length);
    return Right(
      ChatRoomsPage(
        rooms: rooms.sublist(start, end),
        skip: skip,
        limit: limit,
        total: rooms.length,
      ),
    );
  }

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async =>
      const Left(NotFoundFailure('not used'));

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  }) async =>
      const Right(ChatMessagesPage(messages: [], skip: 0, limit: 0, total: 0));

  @override
  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  }) async => const Left(NotFoundFailure('not used'));

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
  Future<Either<Failure, Unit>> deleteMessage(
    String roomId, {
    required String messageId,
  }) async => const Right(unit);

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> addReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => const Right([]);

  @override
  Future<Either<Failure, List<ChatMessageReactionDTO>>> removeReaction(
    String roomId, {
    required String messageId,
    required String emoji,
  }) async => const Right([]);
}

/// No signed-in user, so the notifier skips seeding the room cache and the
/// storage stack behind it never has to exist.
class _FakeUserNotifier extends StateNotifier<UserState>
    implements UserNotifier {
  _FakeUserNotifier() : super(const UserState.initial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// autoDispose tears the provider down the moment nothing listens, so tests
/// hold a subscription open for the life of the container.
ChatRoomsNotifier _keepAlive(ProviderContainer container) {
  container.listen(chatRoomsProvider, (_, _) {});
  return container.read(chatRoomsProvider.notifier);
}

/// Lets the constructor's `loadInitial` (and any pending fetch) settle.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> _ids(ChatRoomsNotifier notifier) =>
    notifier.state.rooms.map((room) => room.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGroupChatRepository repository;
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        groupChatRepositoryProvider.overrideWithValue(repository),
        userProvider.overrideWith((ref) => _FakeUserNotifier()),
      ],
    );
  }

  tearDown(() => container.dispose());

  group('loadInitial', () {
    test(
      'walks past a first page of direct messages to the group rooms',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            for (var i = 0; i < 20; i++) _direct(i),
            _group(1),
            _group(2),
          ],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(_ids(notifier), ['group-room-1', 'group-room-2']);
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.hasMore, isFalse);
        expect(notifier.state.skip, 22);
        expect(repository.listCallCount, 2);
      },
    );

    test('does not mark the list loaded until the walk is over', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 20; i++) _direct(i), _group(1)],
      );
      container = buildContainer();
      final notifier = _keepAlive(container);

      final seen = <ChatRoomsState>[];
      container.listen(chatRoomsProvider, (_, next) => seen.add(next));
      await _settle();

      // No intermediate state was both loaded and empty — that would have
      // flashed the empty state while the group rooms were still on the way.
      expect(
        seen.where((s) => s.hasLoaded && s.rooms.isEmpty && s.error == null),
        isEmpty,
      );
      expect(notifier.state.rooms, hasLength(1));
    });

    test('stops once a page of group rooms is held', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 60; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.skip, 20);
      expect(repository.listCallCount, 1);
    });

    test(
      'caps the walk once it has something to show, so a DM-heavy account '
      'is not crawled whole',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [_group(1), for (var i = 0; i < 200; i++) _direct(i)],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(repository.listCallCount, 5);
        expect(notifier.state.rooms, hasLength(1));
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.hasMore, isTrue);
        expect(notifier.state.skip, 100);
      },
    );

    test(
      'keeps walking past the cap while it has found nothing, so group rooms '
      'behind many pages of DMs are not hidden behind an empty screen',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [for (var i = 0; i < 130; i++) _direct(i), _group(1)],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(repository.listCallCount, 7);
        expect(notifier.state.rooms.map((r) => r.id), ['group-room-1']);
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.hasMore, isFalse);
        expect(notifier.state.skip, 131);
      },
    );

    test(
      'an account with only direct messages ends with the server exhausted, '
      'never an empty list that still claims more',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [for (var i = 0; i < 200; i++) _direct(i)],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(repository.listCallCount, 10);
        expect(notifier.state.rooms, isEmpty);
        expect(notifier.state.hasLoaded, isTrue);
        expect(notifier.state.hasMore, isFalse);
        expect(notifier.state.skip, 200);
      },
    );

    test(
      'a page failing mid-walk keeps what landed and surfaces the error',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            _group(1),
            for (var i = 0; i < 19; i++) _direct(i),
            _group(2),
          ],
        )..failCall = 2;
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();

        expect(_ids(notifier), ['group-room-1']);
        expect(notifier.state.error, isNotNull);
        expect(notifier.state.hasLoaded, isTrue);
        // Paging resumes from the failed page rather than the top.
        expect(notifier.state.skip, 20);
        expect(notifier.state.hasMore, isTrue);

        await notifier.loadMore();
        expect(_ids(notifier), ['group-room-1', 'group-room-2']);
        expect(notifier.state.error, isNull);
      },
    );
  });

  group('loadMore', () {
    test('appends the next page of group rooms without duplicates', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 30; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      await notifier.loadMore();

      expect(notifier.state.rooms, hasLength(30));
      expect(_ids(notifier).toSet(), hasLength(30));
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.skip, 30);
    });

    test(
      'walks past a page of direct messages to reach more group rooms',
      () async {
        repository = _FakeGroupChatRepository(
          rooms: [
            for (var i = 0; i < 20; i++) _group(i),
            for (var i = 0; i < 20; i++) _direct(i),
            _group(99),
          ],
        );
        container = buildContainer();

        final notifier = _keepAlive(container);
        await _settle();
        expect(repository.listCallCount, 1);

        await notifier.loadMore();

        expect(notifier.state.rooms, hasLength(21));
        expect(_ids(notifier), contains('group-room-99'));
        expect(notifier.state.hasMore, isFalse);
        expect(repository.listCallCount, 3);
      },
    );
  });

  group('refresh', () {
    test('a page that a refresh overtook is dropped, not merged', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 40; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.rooms, hasLength(20));

      // The second page is held while a refresh goes out and lands first.
      final hold = repository.holdNextList = Completer<void>();
      final loadingMore = notifier.loadMore();
      await _settle();
      expect(notifier.state.isLoadingMore, isTrue);

      await notifier.refresh();
      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.skip, 20);

      hold.complete();
      await loadingMore;

      // The stale page belongs to the list the refresh replaced.
      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.skip, 20);
      expect(notifier.state.isLoadingMore, isFalse);

      // Paging on from the fresh list still works.
      await notifier.loadMore();
      expect(notifier.state.rooms, hasLength(40));
      expect(_ids(notifier).toSet(), hasLength(40));
    });

    test('a failed refresh keeps the list and its paging', () async {
      repository = _FakeGroupChatRepository(
        rooms: [for (var i = 0; i < 40; i++) _group(i)],
      );
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();

      repository.listFailure = const NetworkFailure('offline');
      await notifier.refresh();

      expect(notifier.state.rooms, hasLength(20));
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.skip, 20);
      expect(notifier.state.hasMore, isTrue);

      repository.listFailure = null;
      await notifier.loadMore();
      expect(notifier.state.rooms, hasLength(40));
      expect(_ids(notifier).toSet(), hasLength(40));
      expect(notifier.state.error, isNull);
    });

    test('a refresh that shrinks the list replaces it', () async {
      repository = _FakeGroupChatRepository(rooms: [_group(1), _group(2)]);
      container = buildContainer();

      final notifier = _keepAlive(container);
      await _settle();
      expect(notifier.state.rooms, hasLength(2));

      repository.rooms = [_group(2)];
      await notifier.refresh();

      expect(_ids(notifier), ['group-room-2']);
      expect(notifier.state.skip, 1);
      expect(notifier.state.total, 1);
    });
  });

  test('hasUnread follows the unread counts', () async {
    repository = _FakeGroupChatRepository(
      rooms: [_group(1), _group(2, unreadCount: 3)],
    );
    container = buildContainer();

    final notifier = _keepAlive(container);
    await _settle();
    expect(notifier.state.hasUnread, isTrue);

    repository.rooms = [_group(1), _group(2)];
    await notifier.refresh();
    expect(notifier.state.hasUnread, isFalse);
  });
}
