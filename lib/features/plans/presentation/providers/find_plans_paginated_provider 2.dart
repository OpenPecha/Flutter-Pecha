import 'package:flutter_pecha/features/plans/data/repositories/plans_repository.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for paginated plans list
class FindPlansState {
  final List<PlansModel> plans;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;

  const FindPlansState({
    this.plans = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
  });

  FindPlansState copyWith({
    List<PlansModel>? plans,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
  }) {
    return FindPlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
    );
  }
}

/// StateNotifier for paginated find plans
class FindPlansNotifier extends StateNotifier<FindPlansState> {
  final PlansRepository repository;
  final String languageCode;
  static const int _limit = 20;

  FindPlansNotifier({required this.repository, required this.languageCode})
    : super(const FindPlansState()) {
    loadInitial();
  }

  /// Load initial plans
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final plans = await repository.getPlans(
        language: languageCode,
        skip: 0,
        limit: _limit,
      );

      if (mounted) {
        state = state.copyWith(
          plans: plans,
          isLoading: false,
          hasMore: plans.length >= _limit,
          skip: plans.length,
          error: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Load more plans
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final newPlans = await repository.getPlans(
        language: languageCode,
        skip: state.skip,
        limit: _limit,
      );

      if (mounted) {
        state = state.copyWith(
          plans: [...state.plans, ...newPlans],
          isLoadingMore: false,
          hasMore: newPlans.length >= _limit,
          skip: state.skip + newPlans.length,
          error: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoadingMore: false, error: e.toString());
      }
    }
  }

  /// Retry loading
  void retry() {
    if (state.plans.isEmpty) {
      loadInitial();
    } else {
      loadMore();
    }
  }

  /// Refresh from start
  Future<void> refresh() async {
    state = const FindPlansState();
    await loadInitial();
  }
}
