import 'package:flutter_pecha/features/plans/data/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for paginated my plans list
class MyPlansState {
  final List<UserPlansModel> plans;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int skip;
  final int total;

  const MyPlansState({
    this.plans = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.skip = 0,
    this.total = 0,
  });

  MyPlansState copyWith({
    List<UserPlansModel>? plans,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? skip,
    int? total,
  }) {
    return MyPlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      total: total ?? this.total,
    );
  }
}

/// StateNotifier for paginated my plans
class MyPlansNotifier extends StateNotifier<MyPlansState> {
  final UserPlansRepository repository;
  final String languageCode;
  static const int _limit = 20;

  MyPlansNotifier({required this.repository, required this.languageCode})
    : super(const MyPlansState()) {
    loadInitial();
  }

  /// Load initial plans
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await repository.getUserPlans(language: languageCode);

      if (mounted) {
        state = state.copyWith(
          plans: response.userPlans,
          isLoading: false,
          hasMore: response.userPlans.length >= _limit,
          skip: response.userPlans.length,
          total: response.total,
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
      final response = await repository.getUserPlans(language: languageCode);

      if (mounted) {
        state = state.copyWith(
          plans: [...state.plans, ...response.userPlans],
          isLoadingMore: false,
          hasMore:
              state.plans.length + response.userPlans.length < response.total,
          skip: state.skip + response.userPlans.length,
          total: response.total,
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
    state = const MyPlansState();
    await loadInitial();
  }
}
