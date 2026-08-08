import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectEventsState {
  final List<GroupEvent> events;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const ConnectEventsState({
    this.events = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  ConnectEventsState copyWith({
    List<GroupEvent>? events,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    bool clearError = false,
  }) {
    return ConnectEventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

class ConnectEventsNotifier extends StateNotifier<ConnectEventsState> {
  ConnectEventsNotifier({
    required this.ref,
    required this.includeUnfollowed,
    required this.language,
  }) : super(const ConnectEventsState());

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
      state = const ConnectEventsState(hasMore: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await ref.read(groupProfileRepositoryProvider).getConnectEvents(
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
          events: page.events,
          isLoading: false,
          hasMore: page.hasMore,
          skip: page.events.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final result = await ref.read(groupProfileRepositoryProvider).getConnectEvents(
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
          events: [...state.events, ...page.events],
          isLoadingMore: false,
          hasMore: page.hasMore,
          skip: state.skip + page.events.length,
          clearError: true,
        );
      },
    );
  }

  Future<void> refresh() async {
    _loadRequested = false;
    state = const ConnectEventsState();
    ensureLoaded();
  }

  void retry() {
    if (state.events.isEmpty) {
      _loadRequested = false;
      ensureLoaded();
    } else {
      loadMore();
    }
  }
}

final myConnectEventsProvider =
    StateNotifierProvider.autoDispose<ConnectEventsNotifier, ConnectEventsState>((
      ref,
    ) {
      final language = ref.watch(contentLanguageProvider);
      return ConnectEventsNotifier(
        ref: ref,
        includeUnfollowed: false,
        language: language,
      );
    });

final discoverConnectEventsProvider =
    StateNotifierProvider.autoDispose<ConnectEventsNotifier, ConnectEventsState>((
      ref,
    ) {
      final language = ref.watch(contentLanguageProvider);
      return ConnectEventsNotifier(
        ref: ref,
        includeUnfollowed: true,
        language: language,
      );
    });
