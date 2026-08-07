import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectPostsState {
  final List<ConnectPost> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const ConnectPostsState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  ConnectPostsState copyWith({
    List<ConnectPost>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return ConnectPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class ConnectPostsNotifier extends StateNotifier<ConnectPostsState> {
  ConnectPostsNotifier({
    required this.ref,
    required this.includeUnfollowed,
  }) : super(const ConnectPostsState());

  final Ref ref;
  final bool includeUnfollowed;
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
      state = const ConnectPostsState(hasMore: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref.read(connectRepositoryProvider).getConnectPosts(
      includeUnfollowed: includeUnfollowed,
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
          posts: page.posts,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.posts.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await ref.read(connectRepositoryProvider).getConnectPosts(
      includeUnfollowed: includeUnfollowed,
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
          posts: [...state.posts, ...page.posts],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.posts.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> refresh() async {
    _loadRequested = false;
    state = const ConnectPostsState();
    ensureLoaded();
  }

  void retry() {
    if (state.posts.isEmpty) {
      _loadRequested = false;
      ensureLoaded();
    } else {
      loadMore();
    }
  }

  void updatePost(ConnectPost updatedPost) {
    final index = state.posts.indexWhere((post) => post.id == updatedPost.id);
    if (index == -1) return;

    final updatedPosts = [...state.posts];
    updatedPosts[index] = updatedPost;
    state = state.copyWith(posts: updatedPosts);
  }
}

final myConnectPostsProvider =
    StateNotifierProvider.autoDispose<ConnectPostsNotifier, ConnectPostsState>((
      ref,
    ) {
      return ConnectPostsNotifier(ref: ref, includeUnfollowed: false);
    });

final discoverConnectPostsProvider =
    StateNotifierProvider.autoDispose<ConnectPostsNotifier, ConnectPostsState>((
      ref,
    ) {
      return ConnectPostsNotifier(ref: ref, includeUnfollowed: true);
    });
