import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_rooms_list.dart';
import 'package:flutter_pecha/features/push_notifications/presentation/providers/push_notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref
        .read(groupChatRepositoryProvider)
        .listRooms(skip: 0, limit: _limit);

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          hasLoaded: true,
          error: failure.message,
        );
      },
      (page) {
        state = state.copyWith(
          rooms: groupChatRooms(page.rooms),
          isLoading: false,
          hasLoaded: true,
          // Against the raw page, not the filtered list: direct rooms count
          // towards the server's total, so a page that is all DMs still means
          // there is more to walk.
          hasMore: page.rooms.isNotEmpty && page.rooms.length < page.total,
          skip: page.rooms.length,
          total: page.total,
          clearError: true,
        );
        _seedRoomCache(page.rooms);
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await ref
        .read(groupChatRepositoryProvider)
        .listRooms(skip: state.skip, limit: _limit);

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        // Re-sorted across the whole list rather than appended: a later page
        // can hold a room more recent than one already shown, since the
        // server's own ordering is undocumented.
        final known = state.rooms.map((room) => room.id).toSet();
        final merged = [
          ...state.rooms,
          ...page.rooms.where((room) => !known.contains(room.id)),
        ];
        final skip = state.skip + page.rooms.length;

        state = state.copyWith(
          rooms: groupChatRooms(merged),
          isLoadingMore: false,
          hasMore: page.rooms.isNotEmpty && skip < page.total,
          skip: skip,
          total: page.total,
          clearError: true,
        );
        _seedRoomCache(page.rooms);
      },
    );
  }

  /// Reloads from the top, keeping what is on screen until the page lands so
  /// the list does not blink back to a spinner on every refresh.
  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(skip: 0, hasMore: true);
    await loadInitial();
  }

  void retry() {
    if (state.rooms.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
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
