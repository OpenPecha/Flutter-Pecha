import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/data/providers/ai_chat_provider.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThreadListState {
  final List<ChatThreadSummary> threads;
  final bool isLoading;
  final String? error;
  final int total;

  ThreadListState({
    this.threads = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
  });

  ThreadListState copyWith({
    List<ChatThreadSummary>? threads,
    bool? isLoading,
    String? error,
    int? total,
  }) {
    return ThreadListState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      total: total ?? this.total,
    );
  }
}

class ThreadListController extends StateNotifier<ThreadListState> {
  final AiChatRepository _repository;
  final _logger = AppLogger('ThreadListController');
  bool _hasLoadedOnce = false;

  ThreadListController(this._repository) : super(ThreadListState());

  /// Load threads list (cached - won't reload if already loaded)
  Future<void> loadThreads() async {
    if (_hasLoadedOnce && state.threads.isNotEmpty) {
      _logger.debug('Threads already loaded, skipping');
      return;
    }

    await _fetchThreads();
  }

  /// Force refresh threads list
  Future<void> refreshThreads() async {
    _logger.info('Refreshing threads list');
    await _fetchThreads();
  }

  Future<void> _fetchThreads() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getThreads(skip: 0, limit: 50);
      state = state.copyWith(
        threads: response.data,
        total: response.total,
        isLoading: false,
      );
      _hasLoadedOnce = true;
      _logger.info('Loaded ${response.data.length} threads');
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
}

final threadListControllerProvider =
    StateNotifierProvider<ThreadListController, ThreadListState>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return ThreadListController(repository);
});

