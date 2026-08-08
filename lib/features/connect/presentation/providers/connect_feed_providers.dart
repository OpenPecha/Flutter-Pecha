import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectFeedState {
  final List<ConnectFeedItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const ConnectFeedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  ConnectFeedState copyWith({
    List<ConnectFeedItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return ConnectFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class ConnectFeedNotifier extends StateNotifier<ConnectFeedState> {
  ConnectFeedNotifier({
    required this.ref,
    required this.includeUnfollowed,
    required this.language,
  }) : super(const ConnectFeedState());

  final Ref ref;
  final bool includeUnfollowed;
  final String language;
  static const int _limit = 20;
  bool _loadRequested = false;

  void ensureLoaded() {
    if (_loadRequested) return;
    _loadRequested = true;
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final authState = ref.read(authProvider);
    if (!includeUnfollowed && (authState.isGuest || !authState.isLoggedIn)) {
      state = const ConnectFeedState(hasMore: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref.read(connectRepositoryProvider).getConnectFeeds(
      includeUnfollowed: includeUnfollowed,
      language: language,
      skip: 0,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          items: page.items,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.items.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await ref.read(connectRepositoryProvider).getConnectFeeds(
      includeUnfollowed: includeUnfollowed,
      language: language,
      skip: state.skip,
      limit: _limit,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, error: failure.message);
      },
      (page) {
        state = state.copyWith(
          items: [...state.items, ...page.items],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.items.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> refresh() async {
    _loadRequested = false;
    state = const ConnectFeedState();
    ensureLoaded();
  }

  void retry() {
    if (state.items.isEmpty) {
      _loadRequested = false;
      ensureLoaded();
    } else {
      loadMore();
    }
  }

  void updatePost(ConnectPost updatedPost) {
    final index = state.items.indexWhere(
      (item) =>
          item.type == ConnectFeedItemType.post &&
          item.post?.id == updatedPost.id,
    );
    if (index == -1) return;

    final item = state.items[index];
    if (item.post == null) return;

    final updatedItems = [...state.items];
    updatedItems[index] = item.copyWithPost(updatedPost);
    state = state.copyWith(items: updatedItems);
  }
}

final myConnectFeedProvider =
    StateNotifierProvider.autoDispose<ConnectFeedNotifier, ConnectFeedState>((
      ref,
    ) {
      final language = ref.watch(contentLanguageProvider);
      return ConnectFeedNotifier(
        ref: ref,
        includeUnfollowed: false,
        language: language,
      );
    });

final discoverConnectFeedProvider =
    StateNotifierProvider.autoDispose<ConnectFeedNotifier, ConnectFeedState>((
      ref,
    ) {
      final language = ref.watch(contentLanguageProvider);
      return ConnectFeedNotifier(
        ref: ref,
        includeUnfollowed: true,
        language: language,
      );
    });
