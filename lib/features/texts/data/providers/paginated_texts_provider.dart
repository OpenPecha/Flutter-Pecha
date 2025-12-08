import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginatedTextsState {
  final List<Texts> texts;
  final Collections? collection;
  final int total;
  final int skip;
  final int limit;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  PaginatedTextsState({
    this.texts = const [],
    this.collection,
    this.total = 0,
    this.skip = 0,
    this.limit = 20,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedTextsState copyWith({
    List<Texts>? texts,
    Collections? collection,
    int? total,
    int? skip,
    int? limit,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedTextsState(
      texts: texts ?? this.texts,
      collection: collection ?? this.collection,
      total: total ?? this.total,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class PaginatedTextsNotifier extends StateNotifier<PaginatedTextsState> {
  final Ref ref;
  final String collectionId;

  PaginatedTextsNotifier(this.ref, this.collectionId)
      : super(PaginatedTextsState()) {
    loadInitialTexts();
  }

  Future<void> loadInitialTexts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final locale = ref.read(localeProvider);
      final repository = ref.read(textsRepositoryProvider);
      final response = await repository.getTexts(
        termId: collectionId,
        language: locale.languageCode,
        skip: 0,
        limit: state.limit,
      );

      state = state.copyWith(
        texts: response.texts,
        collection: response.collections,
        total: response.total,
        skip: response.skip,
        limit: response.limit,
        isLoading: false,
        hasMore: response.texts.length < response.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreTexts() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final locale = ref.read(localeProvider);
      final repository = ref.read(textsRepositoryProvider);
      final nextSkip = state.texts.length;

      final response = await repository.getTexts(
        termId: collectionId,
        language: locale.languageCode,
        skip: nextSkip,
        limit: state.limit,
      );

      final updatedTexts = [...state.texts, ...response.texts];

      state = state.copyWith(
        texts: updatedTexts,
        total: response.total,
        skip: response.skip,
        limit: response.limit,
        isLoading: false,
        hasMore: updatedTexts.length < response.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = PaginatedTextsState(limit: state.limit);
    await loadInitialTexts();
  }
}

final paginatedTextsProvider = StateNotifierProvider.family<
    PaginatedTextsNotifier, PaginatedTextsState, String>(
  (ref, collectionId) => PaginatedTextsNotifier(ref, collectionId),
);
