import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/plans_repository.dart';
import '../datasource/plans_remote_datasource.dart';
import '../../models/plans_model.dart';
import '../../presentation/providers/plan_search_provider.dart';
import '../../presentation/providers/find_plans_paginated_provider.dart';

// Repository provider
final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(
    plansRemoteDatasource: PlansRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

// Get all plans provider
final plansFutureProvider = FutureProvider<List<PlansModel>>((ref) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref.watch(plansRepositoryProvider).getPlans(language: languageCode);
  // return Future.value(mockPlans);
});

final planByIdFutureProvider = FutureProvider.family<PlansModel, String>((
  ref,
  id,
) {
  return ref.watch(plansRepositoryProvider).getPlanById(id);
});

// Find plans with pagination provider
final findPlansPaginatedProvider =
    StateNotifierProvider<FindPlansNotifier, FindPlansState>((ref) {
      final repository = ref.watch(plansRepositoryProvider);
      final locale = ref.watch(localeProvider);
      return FindPlansNotifier(
        repository: repository,
        languageCode: locale.languageCode,
      );
    });

// Plan search provider
final planSearchProvider =
    StateNotifierProvider<PlanSearchNotifier, PlanSearchState>((ref) {
      final repository = ref.watch(plansRepositoryProvider);
      final locale = ref.watch(localeProvider);
      return PlanSearchNotifier(
        repository: repository,
        languageCode: locale.languageCode,
      );
    });
