import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/data/providers/ai_chat_provider.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';
import 'package:flutter_pecha/features/auth/application/user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThreadListState {
  final List<ChatThreadSummary> threads;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int total;
  final DateTime? lastFetchTime;

  ThreadListState({
    this.threads = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.total = 0,
    this.lastFetchTime,
  });

  ThreadListState copyWith({
    List<ChatThreadSummary>? threads,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? total,
    DateTime? lastFetchTime,
  }) {
    return ThreadListState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      total: total ?? this.total,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }

  bool get hasMore => threads.length < total;
  bool get isStale {
    if (lastFetchTime == null) return true;
    final now = DateTime.now();
    return now.difference(lastFetchTime!) > const Duration(seconds: 30);
  }
}

class ThreadListController extends StateNotifier<ThreadListState> {
  final AiChatRepository _repository;
  final Ref _ref;
  final _logger = AppLogger('ThreadListController');

  ThreadListController(this._repository, this._ref) : super(ThreadListState());

  /// Get user email for authenticated users
  String? _getUserEmail() {
    final userState = _ref.read(userProvider);
    
    // Only return email if user is authenticated
    if (userState.isAuthenticated && 
        userState.user?.email != null && 
        userState.user!.email!.isNotEmpty) {
      return userState.user!.email!;
    }
    
    return null;
  }

  /// Load threads list (smart caching - reload if stale)
  Future<void> loadThreads() async {
    // Check if user is authenticated
    final email = _getUserEmail();
    if (email == null) {
      _logger.debug('User not authenticated, skipping thread load');
      return;
    }

    // If data is fresh, skip reload
    if (state.threads.isNotEmpty && !state.isStale) {
      _logger.debug('Threads already loaded and fresh, skipping');
      return;
    }

    await _fetchThreads(email);
  }

  /// Force refresh threads list (always reload)
  Future<void> refreshThreads() async {
    final email = _getUserEmail();
    if (email == null) {
      _logger.debug('User not authenticated, skipping thread refresh');
      return;
    }

    _logger.info('Force refreshing threads list');
    await _fetchThreads(email, forceRefresh: true);
  }

  /// Load more threads (pagination)
  Future<void> loadMoreThreads() async {
    // Don't load if already loading or no more threads
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }

    final email = _getUserEmail();
    if (email == null) {
      _logger.debug('User not authenticated, skipping load more');
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final skip = state.threads.length;
      _logger.info('Loading more threads (skip: $skip)');
      
      final response = await _repository.getThreads(
        email: email,
        skip: skip,
        limit: 10,
      );
      
      state = state.copyWith(
        threads: [...state.threads, ...response.data],
        total: response.total,
        isLoadingMore: false,
        lastFetchTime: DateTime.now(),
      );
      
      _logger.info('Loaded ${response.data.length} more threads');
    } catch (e, stackTrace) {
      _logger.error('Error loading more threads', e, stackTrace);
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _fetchThreads(String email, {bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getThreads(
        email: email,
        skip: 0,
        limit: 10,
      );
      
      state = state.copyWith(
        threads: response.data,
        total: response.total,
        isLoading: false,
        lastFetchTime: DateTime.now(),
      );
      
      _logger.info('Loaded ${response.data.length} threads (total: ${response.total})');
    } catch (e, stackTrace) {
      _logger.error('Error loading threads', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state (for logout)
  void reset() {
    state = ThreadListState();
  }
}

final threadListControllerProvider =
    StateNotifierProvider<ThreadListController, ThreadListState>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return ThreadListController(repository, ref);
});

