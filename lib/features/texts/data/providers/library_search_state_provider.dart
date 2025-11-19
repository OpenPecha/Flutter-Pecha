import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for library search
class LibrarySearchState {
  final String searchQuery;
  final String submittedQuery;
  final bool hasSubmitted;

  const LibrarySearchState({
    this.searchQuery = '',
    this.submittedQuery = '',
    this.hasSubmitted = false,
  });

  LibrarySearchState copyWith({
    String? searchQuery,
    String? submittedQuery,
    bool? hasSubmitted,
  }) {
    return LibrarySearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    );
  }
}

/// Notifier for managing library search state
class LibrarySearchStateNotifier extends StateNotifier<LibrarySearchState> {
  LibrarySearchStateNotifier() : super(const LibrarySearchState());

  /// Update the current search query (as user types)
  void updateSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      // Reset submitted state if user modifies the query
      hasSubmitted: query != state.submittedQuery ? false : state.hasSubmitted,
      submittedQuery: query.isEmpty ? '' : state.submittedQuery,
    );
  }

  /// Submit the search query (when user presses enter or search button)
  void submitSearch(String query) {
    if (query.isNotEmpty) {
      state = state.copyWith(
        searchQuery: query,
        submittedQuery: query,
        hasSubmitted: true,
      );
    }
  }

  /// Clear the search
  void clearSearch() {
    state = const LibrarySearchState();
  }
}

/// Provider for library search state
final librarySearchStateProvider = StateNotifierProvider.autoDispose<
  LibrarySearchStateNotifier,
  LibrarySearchState
>((ref) => LibrarySearchStateNotifier());
