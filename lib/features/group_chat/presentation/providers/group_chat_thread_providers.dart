import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupChatThreadState extends Equatable {
  /// Newest-first, exactly as the API returns them. Rendered through
  /// `ListView(reverse: true)`, so nothing is reversed per rebuild.
  final List<ChatMessageDTO> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  /// Whether the first fetch has settled, so the empty state never flashes
  /// before the initial request lands.
  final bool hasLoaded;

  const GroupChatThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
    this.hasLoaded = false,
  });

  GroupChatThreadState copyWith({
    List<ChatMessageDTO>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
    bool? hasLoaded,
    bool clearError = false,
  }) {
    return GroupChatThreadState(
      messages: messages ?? this.messages,
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
    messages,
    isLoading,
    isLoadingMore,
    error,
    hasMore,
    skip,
    total,
    hasLoaded,
  ];
}

class GroupChatThreadNotifier extends StateNotifier<GroupChatThreadState> {
  GroupChatThreadNotifier({required this.ref, required this.roomId})
    : super(const GroupChatThreadState()) {
    loadInitial();
  }

  final Ref ref;
  final String roomId;
  static const int _limit = 30;

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref
        .read(groupChatRepositoryProvider)
        .listMessages(roomId, skip: 0, limit: _limit);

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
          messages: page.messages,
          isLoading: false,
          hasLoaded: true,
          hasMore: page.messages.length < page.total,
          skip: page.messages.length,
          total: page.total,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await ref
        .read(groupChatRepositoryProvider)
        .listMessages(roomId, skip: state.skip, limit: _limit);

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        // Older messages are a tail append in newest-first order. Ids already
        // held are dropped so a live insert shifting the window cannot
        // duplicate a row.
        final known = state.messages.map((message) => message.id).toSet();
        final fresh =
            page.messages
                .where((message) => !known.contains(message.id))
                .toList();
        final messages = [...state.messages, ...fresh];
        state = state.copyWith(
          messages: messages,
          isLoadingMore: false,
          hasMore: page.messages.isNotEmpty && messages.length < page.total,
          skip: state.skip + page.messages.length,
          total: page.total,
          clearError: true,
        );
      },
    );
  }

  /// Inserts a message that arrived over the socket or came back from a REST
  /// send. Deduped by id, so a send that also echoes as `message_created`
  /// produces exactly one row.
  void appendLive(ChatMessageDTO message) {
    if (message.id.isEmpty) return;
    if (state.messages.any((existing) => existing.id == message.id)) return;
    state = state.copyWith(
      messages: [message, ...state.messages],
      skip: state.skip + 1,
      total: state.total + 1,
      hasLoaded: true,
    );
  }

  /// Re-reads the newest page after a reconnect and merges by id, so anything
  /// missed while the socket was down lands without duplicating what is held.
  Future<void> refreshLatest() async {
    final result = await ref
        .read(groupChatRepositoryProvider)
        .listMessages(roomId, skip: 0, limit: _limit);

    if (!mounted) return;

    result.fold((_) {}, (page) {
      if (state.messages.isEmpty) {
        state = state.copyWith(
          messages: page.messages,
          hasLoaded: true,
          hasMore: page.messages.length < page.total,
          skip: page.messages.length,
          total: page.total,
          clearError: true,
        );
        return;
      }
      // Oldest first, so each insert lands above the previous one and the
      // newest-first order is preserved.
      for (final message in page.messages.reversed) {
        appendLive(message);
      }
    });
  }

  void retry() {
    if (state.messages.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }
}

final groupChatThreadProvider = StateNotifierProvider.autoDispose
    .family<GroupChatThreadNotifier, GroupChatThreadState, String>((
      ref,
      roomId,
    ) {
      return GroupChatThreadNotifier(ref: ref, roomId: roomId);
    });

/// Identifies a room's sender directory. Names come from the room members
/// endpoint and avatars from the group people endpoint, so both ids are needed.
class ChatDirectoryKey extends Equatable {
  final String roomId;
  final String groupId;

  const ChatDirectoryKey({required this.roomId, required this.groupId});

  @override
  List<Object?> get props => [roomId, groupId];
}

/// `user_id` to display identity, fetched once per room.
///
/// Best-effort by design: either request may fail or 403, and the thread then
/// falls back to the email local part with initials for the avatar.
final groupChatSenderDirectoryProvider = FutureProvider.autoDispose
    .family<Map<String, ChatSender>, ChatDirectoryKey>((ref, key) async {
      final repository = ref.watch(groupChatRepositoryProvider);
      final members = await repository.listRoomMembers(key.roomId);
      final people = await repository.listGroupPeople(key.groupId);

      return buildChatSenderDirectory(
        members: members.fold(
          (_) => const [],
          (ChatRoomMembersPage page) => page.members,
        ),
        people: people.fold(
          (_) => const [],
          (ChatPeoplePage page) => page.people,
        ),
      );
    });

/// Session-lived LRU of fetched previews. A stored null means "tried and
/// failed", so a dead link is not refetched.
class ChatLinkPreviewCache {
  ChatLinkPreviewCache({this.capacity = 100});

  final int capacity;
  final Map<String, ChatLinkPreview?> _entries = {};

  bool contains(String url) => _entries.containsKey(url);

  ChatLinkPreview? read(String url) {
    if (!_entries.containsKey(url)) return null;
    // Re-insert to mark most-recently-used.
    final value = _entries.remove(url);
    _entries[url] = value;
    return value;
  }

  void write(String url, ChatLinkPreview? preview) {
    _entries.remove(url);
    _entries[url] = preview;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }
}

final chatLinkPreviewServiceProvider = Provider<ChatLinkPreviewService>((ref) {
  return ChatLinkPreviewService();
});

final chatLinkPreviewCacheProvider = Provider<ChatLinkPreviewCache>((ref) {
  return ChatLinkPreviewCache();
});

/// Resolves the unfurl card for one URL. The bubble paints its text
/// immediately and the card fades in behind this.
final chatLinkPreviewProvider = FutureProvider.autoDispose
    .family<ChatLinkPreview?, String>((ref, url) async {
      final cache = ref.watch(chatLinkPreviewCacheProvider);
      if (cache.contains(url)) return cache.read(url);

      final preview = await ref.watch(chatLinkPreviewServiceProvider).fetch(url);
      cache.write(url, preview);
      return preview;
    });
