import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PoemsViewerState {
  final List<Poem> poems;
  final int skip;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasLoaded;
  final String? error;

  /// Index the [PageView] should start on, resolved once loading finishes.
  final int initialIndex;

  const PoemsViewerState({
    this.poems = const [],
    this.skip = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.hasLoaded = false,
    this.error,
    this.initialIndex = 0,
  });

  PoemsViewerState copyWith({
    List<Poem>? poems,
    int? skip,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    bool? hasLoaded,
    String? error,
    int? initialIndex,
  }) {
    return PoemsViewerState(
      poems: poems ?? this.poems,
      skip: skip ?? this.skip,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      error: error,
      initialIndex: initialIndex ?? this.initialIndex,
    );
  }
}

/// Drives the side-scrollable (Instagram-story-like) full-screen poems
/// viewer: loads an initial page, then lazily loads more as the reader
/// swipes near the end.
///
/// If [initialPoemId] isn't found in the first page (e.g. the home preview
/// showed a poem that has since moved further down the list), it is fetched
/// individually via `GET /poems/{poem_id}` and pinned to the front so the
/// tapped card always opens the right poem.
class PoemsViewerNotifier extends StateNotifier<PoemsViewerState> {
  PoemsViewerNotifier({
    required this.ref,
    required this.language,
    this.initialPoemId,
  }) : super(const PoemsViewerState());

  static const _pageSize = 20;

  final Ref ref;
  final String language;
  final String? initialPoemId;

  bool _isFetching = false;

  Future<void> loadInitial() async {
    if (state.hasLoaded || _isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(poemsRepositoryProvider);
    final result = await repository.getPoems(
      language: language,
      skip: 0,
      limit: _pageSize,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (page) async {
        var poems = page.poems;
        var initialIndex = 0;
        final targetId = initialPoemId;

        if (targetId != null && targetId.isNotEmpty) {
          final matchedIndex = poems.indexWhere((p) => p.id == targetId);
          if (matchedIndex >= 0) {
            initialIndex = matchedIndex;
          } else {
            final single = await repository.getPoem(targetId);
            final lookupFailed = single.fold(
              (failure) {
                state = state.copyWith(
                  isLoading: false,
                  error: failure.message,
                );
                return true;
              },
              (poem) {
                poems = [poem, ...poems.where((p) => p.id != poem.id)];
                initialIndex = 0;
                return false;
              },
            );
            if (lookupFailed) return;
          }
        }

        state = state.copyWith(
          poems: poems,
          isLoading: false,
          hasLoaded: true,
          hasMore: page.hasMore,
          skip: page.skip + page.poems.length,
          initialIndex: initialIndex,
        );
      },
    );

    _isFetching = false;
  }

  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) return;
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true);

    final repository = ref.read(poemsRepositoryProvider);
    final result = await repository.getPoems(
      language: language,
      skip: state.skip,
      limit: _pageSize,
    );

    result.fold(
      (failure) {
        // Keep existing poems visible; leave hasMore unchanged so the reader
        // can retry by scrolling near the end again.
        state = state.copyWith(isLoadingMore: false);
      },
      (page) {
        final existingIds = state.poems.map((p) => p.id).toSet();
        final newPoems =
            page.poems.where((p) => !existingIds.contains(p.id)).toList();
        state = state.copyWith(
          poems: [...state.poems, ...newPoems],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.poems.length,
        );
      },
    );

    _isFetching = false;
  }
}

final poemsViewerProvider = StateNotifierProvider.autoDispose
    .family<PoemsViewerNotifier, PoemsViewerState, String?>((
      ref,
      initialPoemId,
    ) {
      ref.watch(contentLanguageProvider);
      final language = poemsApiLanguageCode(ref.read(contentLanguageProvider));
      final notifier = PoemsViewerNotifier(
        ref: ref,
        language: language,
        initialPoemId: initialPoemId,
      );
      notifier.loadInitial();
      return notifier;
    });
