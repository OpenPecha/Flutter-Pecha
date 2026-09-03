import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/chat_link_preview_service.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';
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

  /// Messages this member deleted during this session, shown as a tombstone.
  ///
  /// Deliberately here rather than on [ChatMessageDTO]: the DTO mirrors the
  /// wire, and the wire has no deleted flag — the server hard-deletes and does
  /// not broadcast it. Keeping the marker in state says plainly what it is, a
  /// local overlay that lasts as long as this screen does. Re-entering the
  /// room drops the row entirely, which is what every other member already
  /// sees.
  final Set<String> deletedMessageIds;

  const GroupChatThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
    this.hasLoaded = false,
    this.deletedMessageIds = const {},
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
    Set<String>? deletedMessageIds,
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
      deletedMessageIds: deletedMessageIds ?? this.deletedMessageIds,
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
    deletedMessageIds,
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

  /// Per message, the sequence number of the most recent toggle and the tail
  /// of its in-flight work. Overlapping taps on one message would otherwise
  /// each derive a baseline from the other's optimistic state, then roll back
  /// or apply a summary that no longer matches what the user last chose.
  final Map<String, int> _toggleSeq = {};
  final Map<String, Future<void>> _toggleChain = {};

  /// Per message, the emoji this member holds **on the server**.
  ///
  /// Advanced only by confirmed calls: a successful POST adds, a successful
  /// DELETE removes, a failure changes nothing. Any summary that can identify
  /// the viewer replaces it outright, which is what prunes it.
  ///
  /// It deliberately **outlives the burst**. Rebuilding it from displayed state
  /// each time only works while the display knows which reactions are the
  /// viewer's, and a summary carrying no `users` or `user_ids` cannot say —
  /// so a duplicate left by a failed cleanup would stop being recognised as
  /// owned and could never be retried. Later taps must also never read their
  /// cleanup target from optimistic state: if an earlier queued POST failed,
  /// that state names an emoji the server never received.
  final Map<String, Set<String>> _serverOwn = {};

  /// Messages mid-swap. Between the POST of the new emoji and the DELETE of
  /// the old one the server legitimately holds **both**, and so does any
  /// `reactions_updated` broadcast in that window. Adopting either would show
  /// two emoji for the ~600ms the round trip takes, so summaries for these
  /// messages are ignored until the swap settles.
  final Set<String> _swapping = {};

  /// Bumped whenever a message's reactions change locally. A refetch compares
  /// the value it saw before its request with the value on arrival: checking
  /// `_swapping` alone only asks whether a swap is running *now*, so a page
  /// requested before a swap and delivered after it would overwrite the
  /// freshly confirmed reaction with its own stale snapshot.
  final Map<String, int> _reactionRevision = {};

  /// Summaries that arrived for a message not yet in the loaded window while
  /// a page request was in flight. That page carries a snapshot older than the
  /// broadcast, so the broadcast is held and applied to the row the page
  /// inserts rather than being overwritten by it.
  ///
  /// Only kept while a fetch is running. Outside one the original reasoning
  /// holds: a message outside the window is refetched with current counts
  /// anyway, so dropping the update is correct.
  final Map<String, List<ChatMessageReactionDTO>> _pendingReactions = {};

  /// How many page requests are in flight. A reaction broadcast is only worth
  /// holding while one of them might be carrying the message it names.
  int _fetchesInFlight = 0;

  /// Runs a page request with [_fetchesInFlight] raised for its duration.
  Future<T> _guardFetch<T>(Future<T> Function() fetch) async {
    _fetchesInFlight++;
    try {
      return await fetch();
    } finally {
      _fetchesInFlight--;
    }
  }

  /// Applies a summary held while this page was in flight. It is newer than
  /// the page's own snapshot of the same message.
  ChatMessageDTO _withPendingReactions(ChatMessageDTO message) {
    final pending = _pendingReactions.remove(message.id);
    if (pending == null) return message;
    return message.copyWith(reactions: pending);
  }

  /// Anything still held once no fetch is running names a message no page is
  /// going to insert, so it is dropped rather than kept for good.
  void _dropStalePendingReactions() {
    if (_fetchesInFlight == 0) _pendingReactions.clear();
  }

  void _bumpRevision(String messageId) {
    _reactionRevision[messageId] = (_reactionRevision[messageId] ?? 0) + 1;
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _guardFetch(
      () => ref
          .read(groupChatRepositoryProvider)
          .listMessages(roomId, skip: 0, limit: _limit),
    );

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
          messages: page.messages.map(_withPendingReactions).toList(),
          isLoading: false,
          hasLoaded: true,
          hasMore: page.messages.length < page.total,
          skip: page.messages.length,
          total: page.total,
          clearError: true,
        );
      },
    );
    _dropStalePendingReactions();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await _guardFetch(
      () => ref
          .read(groupChatRepositoryProvider)
          .listMessages(roomId, skip: state.skip, limit: _limit),
    );

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
                .map(_withPendingReactions)
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
    _dropStalePendingReactions();
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
  Future<void> refreshLatest({
    String? currentUserId,
    String? currentUserEmail,
  }) async {
    // Taken before the request goes out, so anything that changes while it is
    // in flight is visible on arrival.
    final revisionsBefore = {
      for (final message in state.messages)
        message.id: _reactionRevision[message.id] ?? 0,
    };
    // Identity is snapshot for the same reason. Only the history held when the
    // request went out can say whether the page that comes back is contiguous
    // with it; a message appended over the socket meanwhile has no standing in
    // that question, and reading it back out of post-await state would let one
    // such insert suppress a restart the gap actually needs.
    final knownBefore = state.messages.map((message) => message.id).toSet();

    final result = await _guardFetch(
      () => ref
          .read(groupChatRepositoryProvider)
          .listMessages(roomId, skip: 0, limit: _limit),
    );

    if (!mounted) return;

    result.fold((_) {}, (page) {
      ChatMessageDTO forViewer(ChatMessageDTO message) {
        final fresh = _withPendingReactions(message);
        if (fresh.reactions.isEmpty) return fresh;
        return fresh.copyWith(
          reactions: chatReactionsForViewer(
            fresh.reactions,
            currentUserId: currentUserId,
            currentUserEmail: currentUserEmail,
          ),
        );
      }

      final fetched = page.messages.map(forViewer).toList();

      if (state.messages.isEmpty) {
        state = state.copyWith(
          messages: fetched,
          hasLoaded: true,
          hasMore: fetched.length < page.total,
          skip: fetched.length,
          total: page.total,
          clearError: true,
        );
        return;
      }

      // A full page with nothing in common with what is held means more
      // arrived while the socket was down than one page can carry. The middle
      // is missing, so the retained tail is not contiguous with it — keeping
      // both would leave `skip` pointing past the gap and those messages
      // would never load. Start again from the newest page and let `loadMore`
      // walk back through the gap.
      final overlaps = fetched.any(
        (message) => knownBefore.contains(message.id),
      );
      if (!overlaps && fetched.length >= _limit) {
        // Restarting must not throw away what the restored socket delivered
        // while this page was in flight. Those messages are newer than the
        // page, so they sit above it — and being newer, they are not in the
        // count the server sent with it either.
        final fetchedIds = fetched.map((message) => message.id).toSet();
        final arrivedDuring =
            state.messages
                .where(
                  (message) =>
                      !knownBefore.contains(message.id) &&
                      !fetchedIds.contains(message.id),
                )
                .toList();

        final messages = [...arrivedDuring, ...fetched];
        final total = page.total + arrivedDuring.length;
        state = state.copyWith(
          messages: messages,
          hasLoaded: true,
          hasMore: messages.length < total,
          skip: messages.length,
          total: total,
          clearError: true,
        );
        return;
      }

      // Refresh what is already held rather than skipping it. A reaction that
      // changed while the socket was down arrives on a message whose id we
      // already have, and `appendLive` alone would drop that update on the
      // floor. A message mid-swap is left alone — its optimistic state is
      // newer than this page.
      final fetchedById = {for (final message in fetched) message.id: message};
      state = state.copyWith(
        messages:
            state.messages.map((existing) {
              final fresh = fetchedById[existing.id];
              if (fresh == null) return existing;

              // Anything touched since this request was sent is newer than the
              // page it brought back, whether or not that work has finished by
              // the time the page arrives.
              final changed =
                  (_reactionRevision[existing.id] ?? 0) !=
                  (revisionsBefore[existing.id] ?? 0);
              if (changed || _swapping.contains(existing.id)) return existing;

              return fresh;
            }).toList(),
      );

      // Oldest first, so each insert lands above the previous one and the
      // newest-first order is preserved.
      for (final message in fetched.reversed) {
        appendLive(message);
      }

      // The server's count is newer than the one carried since the last page.
      state = state.copyWith(
        total: page.total,
        hasMore: state.messages.length < page.total,
      );
    });
    _dropStalePendingReactions();
  }

  /// Rewrites one message's reactions from an authoritative summary — the
  /// REST response to our own call, or a `reactions_updated` broadcast.
  ///
  /// A message that has scrolled out of the loaded window is simply absent;
  /// dropping the update is correct, since `loadMore` refetches with current
  /// counts.
  void replaceReactions(
    String messageId,
    List<ChatMessageReactionDTO> reactions, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    if (_swapping.contains(messageId)) return;
    _applyReactions(
      messageId,
      reactions,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
  }

  void _applyReactions(
    String messageId,
    List<ChatMessageReactionDTO> reactions, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    if (messageId.isEmpty) return;
    if (!state.messages.any((message) => message.id == messageId)) {
      // Not in the loaded window. While a page is in flight that page may be
      // carrying this very message, with a snapshot taken before this update —
      // so the summary is held for the row it inserts. The revision moves with
      // it, so an even older page still in flight cannot overwrite the result.
      if (_fetchesInFlight > 0) {
        _pendingReactions[messageId] = reactions;
        _bumpRevision(messageId);
      }
      return;
    }

    _bumpRevision(messageId);

    // Whenever a summary can say who holds what, it is more authoritative than
    // anything tracked — this is what keeps `_serverOwn` from going stale.
    final own = _ownFromSummary(
      reactions,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
    if (own != null) _serverOwn[messageId] = own;

    final resolved = chatReactionsForViewer(
      reactions,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );

    state = state.copyWith(
      messages:
          state.messages
              .map(
                (message) =>
                    message.id == messageId
                        ? message.copyWith(reactions: resolved)
                        : message,
              )
              .toList(),
    );
  }

  /// Applies a reaction with WhatsApp semantics: a member holds **one**
  /// reaction per message, so tapping a different emoji swaps it.
  ///
  /// The API does not enforce that — add and remove are per-emoji and
  /// idempotent — so the swap is the client's job. The POST goes first so the
  /// message never flickers through a zero-reaction state, and only the
  /// **final** summary is adopted: the one in between has both emoji on it.
  /// Rolls back to the pre-toggle reactions if the first call fails.
  Future<Failure?> toggleReaction(
    String messageId,
    String emoji, {
    required String roomIdForCall,
    String? currentUserId,
    String? currentUserEmail,
  }) async {
    final index = state.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (index < 0) return null;

    final seq = (_toggleSeq[messageId] ?? 0) + 1;
    _toggleSeq[messageId] = seq;

    final baseline = state.messages[index].reactions;
    final previousEmoji = currentChatReactionEmoji(baseline);
    final isRemoval = previousEmoji == emoji;
    final isSwap = !isRemoval && previousEmoji != null;
    if (isSwap) _swapping.add(messageId);

    // First tap of a burst: this baseline is still confirmed state, so it is
    // the only trustworthy seed. Later taps inherit it rather than reseeding
    // from their own optimistic baseline.
    if (!_toggleChain.containsKey(messageId)) {
      // Union, not replacement: what the display knows the viewer holds, plus
      // anything still recorded from an earlier burst whose cleanup failed.
      // Every reaction, not just the first — one failed cleanup leaves two.
      _serverOwn[messageId] = {
        ...?_serverOwn[messageId],
        ...ownChatReactionEmoji(baseline),
      };
    }

    // Optimistic, and synchronously so: the tap has to read as instant, and a
    // broadcast arriving in the same frame must not overwrite it.
    _setReactions(
      messageId,
      toggleChatReaction(
        baseline,
        emoji,
        previousEmoji: previousEmoji,
        viewerId: currentUserId,
        viewerEmail: currentUserEmail,
      ),
    );

    // Only the requests are chained, per message, so the server sees the taps
    // in the order they were made and a rollback can never undo a later
    // choice.
    final queued = _toggleChain[messageId] ?? Future<void>.value();
    Failure? failure;
    final run = queued.then((_) async {
      failure = await _runToggle(
        messageId,
        emoji,
        seq: seq,
        baseline: baseline,
        previousEmoji: previousEmoji,
        isRemoval: isRemoval,
        isSwap: isSwap,
        roomIdForCall: roomIdForCall,
        currentUserId: currentUserId,
        currentUserEmail: currentUserEmail,
      );
    });
    _toggleChain[messageId] = run.catchError((Object _) {});

    await _toggleChain[messageId];
    if (_toggleSeq[messageId] == seq) {
      _toggleSeq.remove(messageId);
      _toggleChain.remove(messageId);
      // `_serverOwn` is not cleared here: an unresolved duplicate has to
      // survive into the next burst to be retried. An identifying summary
      // prunes it instead.
      // The last operation for this message owns the cleanup, whichever one
      // opened the swap guard.
      _swapping.remove(messageId);
    }
    return failure;
  }

  /// Whether this operation is still the newest one for its message. A
  /// superseded toggle neither applies its summary nor rolls back — the newer
  /// one owns the state.
  bool _isCurrent(String messageId, int seq) => _toggleSeq[messageId] == seq;

  Future<Failure?> _runToggle(
    String messageId,
    String emoji, {
    required int seq,
    required List<ChatMessageReactionDTO> baseline,
    required String? previousEmoji,
    required bool isRemoval,
    required bool isSwap,
    required String roomIdForCall,
    String? currentUserId,
    String? currentUserEmail,
  }) async {
    if (!mounted) return null;
    final previousReactions = baseline;

    final repository = ref.read(groupChatRepositoryProvider);
    final result =
        isRemoval
            ? await repository.removeReaction(
              roomIdForCall,
              messageId: messageId,
              emoji: emoji,
            )
            : await repository.addReaction(
              roomIdForCall,
              messageId: messageId,
              emoji: emoji,
            );

    if (!mounted) return null;

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) {
      // Rolling back to this operation's baseline would wipe a newer tap.
      if (_isCurrent(messageId, seq)) {
        _setReactions(messageId, previousReactions);
      }
      return failure;
    }

    var summary = result.getOrElse((_) => const []);

    // This call is confirmed, so the server's state for this member is known
    // exactly: it now holds `emoji` (or no longer does). Prefer a summary that
    // can identify the viewer; otherwise advance what is tracked. Either way
    // the optimistic baseline never decides what gets deleted.
    final own =
        _ownFromSummary(
          summary,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        ) ??
        {...?_serverOwn[messageId]};
    if (isRemoval) {
      own.remove(emoji);
    } else {
      own.add(emoji);
    }
    _serverOwn[messageId] = own;

    // One reaction per member: everything else this member holds is stale.
    final stale = own.where((held) => held != emoji || isRemoval).toList();

    if (stale.isEmpty) {
      if (_isCurrent(messageId, seq)) {
        _applyReactions(
          messageId,
          summary,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        );
      }
      return null;
    }

    // One reaction per member: drop everything else this member holds. The
    // in-between summaries carry more than one emoji, so none of them is
    // applied — only the last.
    Failure? cleanupFailure;
    for (final extra in stale) {
      final dropped = await repository.removeReaction(
        roomIdForCall,
        messageId: messageId,
        emoji: extra,
      );
      if (!mounted) return null;
      dropped.fold(
        (failure) {
          // The member is left holding two on the server. `_serverOwn` keeps
          // `extra`, so a later burst still knows to drop it, and the summary
          // applied below shows both rather than hiding the duplicate — but
          // the caller has to hear about it instead of being told this
          // succeeded.
          cleanupFailure ??= failure;
        },
        (reactions) {
          summary = reactions;
          _serverOwn[messageId]?.remove(extra);
        },
      );
    }

    if (!_isCurrent(messageId, seq)) return cleanupFailure;
    _applyReactions(
      messageId,
      summary,
      currentUserId: currentUserId,
      currentUserEmail: currentUserEmail,
    );
    return cleanupFailure;
  }

  /// The emoji [summary] says this member holds, or null when it cannot say.
  ///
  /// `reacted_by_me` on the wire is not viewer-specific, so the answer comes
  /// from `users` / `user_ids`. Null — rather than an empty set — when the
  /// viewer is unidentifiable, so the caller falls back to what it has tracked
  /// instead of concluding the member holds nothing.
  Set<String>? _ownFromSummary(
    List<ChatMessageReactionDTO> summary, {
    String? currentUserId,
    String? currentUserEmail,
  }) {
    final hasId = (currentUserId ?? '').trim().isNotEmpty;
    final hasEmail = (currentUserEmail ?? '').trim().isNotEmpty;
    if (!hasId && !hasEmail) return null;

    // An empty summary is a definite answer: nobody holds anything.
    if (summary.isEmpty) return <String>{};

    final identifiable = summary.every(
      (reaction) => reaction.users.isNotEmpty || reaction.userIds.isNotEmpty,
    );
    if (!identifiable) return null;

    return chatReactionsForViewer(
          summary,
          currentUserId: currentUserId,
          currentUserEmail: currentUserEmail,
        )
        .where((reaction) => reaction.reactedByMe && reaction.count > 0)
        .map((reaction) => reaction.emoji)
        .toSet();
  }

  void _setReactions(String messageId, List<ChatMessageReactionDTO> reactions) {
    _bumpRevision(messageId);
    state = state.copyWith(
      messages:
          state.messages
              .map(
                (message) =>
                    message.id == messageId
                        ? message.copyWith(reactions: reactions)
                        : message,
              )
              .toList(),
    );
  }

  /// Deletes one of this member's own messages, for everyone.
  ///
  /// The row is left in place until the server confirms. A destructive action
  /// already behind a confirm dialog should not need a rollback that brings
  /// back a message the user watched disappear.
  ///
  /// Returns the failure when the call fails, so the caller can say so.
  Future<Failure?> deleteMessage(String messageId) async {
    if (messageId.isEmpty) return null;
    if (state.deletedMessageIds.contains(messageId)) return null;

    final result = await ref
        .read(groupChatRepositoryProvider)
        .deleteMessage(roomId, messageId: messageId);

    if (!mounted) return null;

    return result.fold((failure) => failure, (_) {
      state = state.copyWith(
        deletedMessageIds: {...state.deletedMessageIds, messageId},
      );
      return null;
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

      final preview = await ref
          .watch(chatLinkPreviewServiceProvider)
          .fetch(url);
      cache.write(url, preview);
      return preview;
    });
