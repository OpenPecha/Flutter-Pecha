import 'dart:async';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/repositories/recitations_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for recitation search
class RecitationSearchState {
  final String query;
  final List<RecitationModel> results;
  final bool isLoading;
  final String? error;

  const RecitationSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  RecitationSearchState copyWith({
    String? query,
    List<RecitationModel>? results,
    bool? isLoading,
    String? error,
  }) {
    return RecitationSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for managing recitation search with debounce
class RecitationSearchNotifier extends StateNotifier<RecitationSearchState> {
  final RecitationsRepository repository;
  final String languageCode;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Shortest query that triggers a network request.
  static const int minQueryLength = 3;

  RecitationSearchNotifier({
    required this.repository,
    required this.languageCode,
  }) : super(const RecitationSearchState());

  /// Search with debounce
  void search(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately for UI feedback
    state = state.copyWith(query: query, isLoading: true, error: null);

    if (query.trim().length < minQueryLength) {
      state = RecitationSearchState(query: query);
      return;
    }

    // Set up debounced search
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    if (query.trim().length < minQueryLength) {
      state = RecitationSearchState(query: query);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await repository.getRecitations(
      language: languageCode,
      searchQuery: query.trim(),
    );

    result.fold(
      (failure) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        }
      },
      (results) {
        if (mounted) {
          state = state.copyWith(
            results: results,
            isLoading: false,
            error: null,
          );
        }
      },
    );
  }

  /// Retry search
  void retry() {
    if (state.query.trim().length >= minQueryLength) {
      _performSearch(state.query);
    }
  }

  /// Clear search
  void clear() {
    _debounceTimer?.cancel();
    state = const RecitationSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
