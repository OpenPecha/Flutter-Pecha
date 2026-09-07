import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Left, Right;

class ChatRoomsState extends Equatable {
  /// Group rooms only, most recently active first.
  final List<ChatRoomDTO> rooms;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  /// Whether the first fetch has settled, so the empty state never flashes
  /// before the initial request lands.
  final bool hasLoaded;

  const ChatRoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
    this.hasLoaded = false,
  });

  /// Drives the dot on the Connect app bar.
  bool get hasUnread => rooms.any(chatRoomIsUnread);

  ChatRoomsState copyWith({
    List<ChatRoomDTO>? rooms,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return ChatRoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  @override
  List<Object?> get props => [
    rooms,
    isLoading,
    isLoadingMore,
    error,
    hasMore,
    skip,
    total,
    hasLoaded,
  ];
}

/// What one walk down `/chat/rooms` brought back.
class _RoomsWalk {
  const _RoomsWalk({
    required this.rooms,
    required this.skip,
    required this.total,
    required this.hasMore,
    this.failure,
  });

  /// Every room fetched, direct messages included, in server order.
  final List<ChatRoomDTO> rooms;

  /// Where the next walk should start.
  final int skip;
  final int total;
  final bool hasMore;

  /// Set when a page failed. Earlier pages of the same walk are still in
  /// [rooms]; a walk whose first page failed has none.
  final Failure? failure;
}

/// The viewer's group chats.
///
/// Read by both the Connect app-bar dot and the Chats screen, so the dot's
/// fetch doubles as the screen's prefetch — there is no unread endpoint, and
/// loading this twice for one answer would be the only alternative.
class ChatRoomsNotifier extends StateNotifier<ChatRoomsState>
    with WidgetsBindingObserver {
  ChatRoomsNotifier({required this.ref}) : super(const ChatRoomsState()) {
    WidgetsBinding.instance.addObserver(this);
    loadInitial();
  }

  final Ref ref;
  static const int _limit = 20;

  /// How many server pages one load will walk in search of group rooms.
  ///
  /// `/chat/rooms` has no kind filter and mixes direct messages in, so a page
  /// can be all DMs and contribute nothing to this list. Left at one page, a
  /// viewer whose first twenty rooms are DMs would see the empty state — and
  /// with no list on screen there is nothing to scroll, so the next page would
  /// never be asked for and their group chats would be hidden for good. The
  /// cap keeps a DM-heavy account from turning every refresh into a crawl of
  /// the whole endpoint.
  static const int _maxPagesPerLoad = 5;

  /// Bumped by every load from the top.
  ///
  /// A `loadMore` that went out before the bump was paging a list that no
  /// longer exists. Merging its page into the fresh list would put its rooms
  /// in twice over and leave `skip` counting rows the new list never held, so
  /// its result is dropped instead.
  int _generation = 0;

  /// Unread counts and last messages both change on the server without the app
  /// hearing about it — the live socket is per-room, and there is no rooms
  /// stream. So this list is refetched on every occasion it could be stale
  /// rather than loaded once: coming back to the foreground, a chat push
  /// landing while the app is open, and whenever the Chats screen is shown.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    _generation++;
    // `hasLoaded` waits for the whole walk, not the first page: with a first
    // page of DMs the list is still empty when it lands, and marking it loaded
    // there would flash the empty state before the group rooms arrive.
    state = state.copyWith(isLoading: true, clearError: true);

    final walk = await _walk(skip: 0);
    if (!mounted) return;

    final failure = walk.failure;
    if (failure != null && walk.rooms.isEmpty) {
      // Nothing new landed; whatever was on screen stays, and so does the
      // paging that goes with it.
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: failure.message,
      );
      return;
    }

    state = state.copyWith(
      rooms: groupChatRooms(walk.rooms),
      isLoading: false,
      hasLoaded: true,
      hasMore: walk.hasMore,
      skip: walk.skip,
      total: walk.total,
      error: failure?.message,
      clearError: failure == null,
    );
    _seedRoomCache(walk.rooms);
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final walk = await _walk(skip: state.skip);
    if (!mounted) return;
    if (generation != _generation) {
      // A load from the top overtook this page. The list it was extending is
      // gone, so there is nothing to append it to.
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    final failure = walk.failure;
    if (failure != null && walk.rooms.isEmpty) {
      state = state.copyWith(isLoadingMore: false, error: failure.message);
      return;
    }

    // Re-sorted across the whole list rather than appended: a later page can
    // hold a room more recent than one already shown, since the server's own
    // ordering is undocumented.
    final known = state.rooms.map((room) => room.id).toSet();
    final merged = [
      ...state.rooms,
      ...walk.rooms.where((room) => !known.contains(room.id)),
    ];

    state = state.copyWith(
      rooms: groupChatRooms(merged),
      isLoadingMore: false,
      hasMore: walk.hasMore,
      skip: walk.skip,
      total: walk.total,
      error: failure?.message,
      clearError: failure == null,
    );
    _seedRoomCache(walk.rooms);
  }

  /// Reloads from the top, keeping what is on screen until the walk lands so
  /// the list does not blink back to a spinner on every refresh. Paging is
  /// only replaced once the new list is, so a refresh that fails leaves the
  /// old list able to page on from where it was.
  Future<void> refresh() => loadInitial();

  void retry() {
    if (state.rooms.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Pages forward from [skip] until a page's worth of group rooms has been
  /// collected, the server runs out, a page fails, or [_maxPagesPerLoad] is
  /// reached — whichever comes first.
  Future<_RoomsWalk> _walk({required int skip}) async {
    final repository = ref.read(groupChatRepositoryProvider);
    final rooms = <ChatRoomDTO>[];
    var total = 0;
    var hasMore = true;

    for (var page = 0; page < _maxPagesPerLoad && hasMore; page++) {
      final result = await repository.listRooms(skip: skip, limit: _limit);
      if (!mounted) break;

      final ChatRoomsPage loaded;
      switch (result) {
        case Left(value: final failure):
          return _RoomsWalk(
            rooms: rooms,
            skip: skip,
            total: total,
            hasMore: hasMore,
            failure: failure,
          );
        case Right(value: final page):
          loaded = page;
      }

      rooms.addAll(loaded.rooms);
      skip += loaded.rooms.length;
      total = loaded.total;
      // Against the raw page, not the filtered list: direct rooms count
      // towards the server's total, so a page that is all DMs still means
      // there is more to walk.
      hasMore = loaded.rooms.isNotEmpty && skip < total;

      if (groupChatRooms(rooms).length >= _limit) break;
    }

    return _RoomsWalk(rooms: rooms, skip: skip, total: total, hasMore: hasMore);
  }

  /// Records room ids against their groups.
  ///
  /// The chat route is keyed by group, so opening a chat runs
  /// `ResolveGroupChatRoom`, which pages this same endpoint looking for the id
  /// this list already has. Writing it here turns that lookup into a cache hit
  /// and the thread opens without a request.
  void _seedRoomCache(List<ChatRoomDTO> rooms) {
    final userId = ref.read(userProvider).user?.id?.trim() ?? '';
    if (userId.isEmpty) return;

    final cache = ref.read(groupChatRoomCacheProvider);
    for (final room in rooms) {
      final groupId = room.groupId;
      if (groupId == null || groupId.isEmpty || room.id.isEmpty) continue;
      // Fire and forget: a failed write only costs the lookup it would have
      // saved, so it must never hold up the list.
      cache.write(userId: userId, groupId: groupId, roomId: room.id);
    }
  }
}

final chatRoomsProvider =
    StateNotifierProvider.autoDispose<ChatRoomsNotifier, ChatRoomsState>((ref) {
      return ChatRoomsNotifier(ref: ref);
    });

/// Refreshes the rooms list when a chat push arrives while the app is open.
///
/// Watched by whatever shows the unread dot, so the dot answers a notification
/// the user is looking at rather than waiting for the next fetch. Deliberately
/// not filtered to any one room: a push for a chat the user is currently
/// reading still changes another room's counts.
final chatRoomsPushRefreshProvider = Provider.autoDispose<void>((ref) {
  final subscription = ref
      .watch(pushMessagingRepositoryProvider)
      .onForegroundMessage
      .listen((message) {
        if (!isChatPushPayload(message.data)) return;
        ref.read(chatRoomsProvider.notifier).refresh();
      });

  ref.onDispose(subscription.cancel);
});
