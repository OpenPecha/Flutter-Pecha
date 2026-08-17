import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/datasource/recitations_remote_datasource.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitation_search_provider.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('PracticeRecitationsNotifier');

const int practiceRecitationsPageSize = 20;

class PracticeRecitationsState {
  final List<RecitationModel> recitations;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  const PracticeRecitationsState({
    this.recitations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
  });

  PracticeRecitationsState copyWith({
    List<RecitationModel>? recitations,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
  }) {
    return PracticeRecitationsState(
      recitations: recitations ?? this.recitations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
    );
  }
}

class PracticeRecitationsNotifier extends StateNotifier<PracticeRecitationsState> {
  final RecitationsRemoteDatasource _datasource;
  final String _languageCode;

  PracticeRecitationsNotifier({
    required RecitationsRemoteDatasource datasource,
    required String languageCode,
  }) : _datasource = datasource,
       _languageCode = languageCode,
       super(const PracticeRecitationsState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = await _datasource.fetchRecitationsPage(
        queryParams: RecitationsQueryParams(
          language: _languageCode,
          skip: 0,
          limit: practiceRecitationsPageSize,
        ),
      );

      if (!mounted) return;
      state = PracticeRecitationsState(
        recitations: page.recitations,
        isLoading: false,
        hasMore: page.hasMore,
        skip: page.recitations.length,
        total: page.total,
      );
    } catch (e) {
      _logger.error('Initial recitations load failed', e);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _datasource.fetchRecitationsPage(
        queryParams: RecitationsQueryParams(
          language: _languageCode,
          skip: state.skip,
          limit: practiceRecitationsPageSize,
        ),
      );

      if (!mounted) return;
      final updatedRecitations = [...state.recitations, ...page.recitations];
      state = state.copyWith(
        recitations: updatedRecitations,
        isLoadingMore: false,
        hasMore: page.hasMore,
        skip: state.skip + page.recitations.length,
        total: page.total,
      );
    } catch (e) {
      _logger.error('Load more recitations failed', e);
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void retry() {
    if (state.recitations.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  Future<void> refresh() async {
    state = const PracticeRecitationsState();
    await loadInitial();
  }
}

class PracticeRecitationsLanguageNotifier extends StateNotifier<String> {
  PracticeRecitationsLanguageNotifier(String initialLanguage)
    : super(initialLanguage);

  void setLanguage(String languageCode) {
    state = languageCode;
  }
}

/// Chant list language for [AllRecitationsScreen]. Does not change app locale.
final practiceRecitationsLanguageProvider = StateNotifierProvider.autoDispose<
  PracticeRecitationsLanguageNotifier,
  String
>((ref) {
  return PracticeRecitationsLanguageNotifier(
    ref.watch(contentLanguageProvider),
  );
});

final practiceRecitationsPaginatedProvider = StateNotifierProvider.autoDispose
    .family<PracticeRecitationsNotifier, PracticeRecitationsState, String>((
      ref,
      languageCode,
    ) {
      return PracticeRecitationsNotifier(
        datasource: RecitationsRemoteDatasource(dio: ref.watch(dioProvider)),
        languageCode: languageCode,
      );
    });

final practiceRecitationSearchProvider = StateNotifierProvider.autoDispose
    .family<RecitationSearchNotifier, RecitationSearchState, String>((
      ref,
      languageCode,
    ) {
      return RecitationSearchNotifier(
        repository: ref.watch(recitationsRepositoryProvider),
        languageCode: languageCode,
      );
    });
