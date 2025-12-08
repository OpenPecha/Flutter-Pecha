import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/providers/plan_days_providers.dart';
import 'package:flutter_pecha/features/plans/data/repositories/user_plans_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/my_plans_paginated_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('UserPlansProvider');

final userPlansRepositoryProvider = Provider<UserPlansRepository>((ref) {
  return UserPlansRepository(
    userPlansRemoteDatasource: UserPlansRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

final userPlansFutureProvider = FutureProvider<UserPlanListResponseModel>((
  ref,
) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale.languageCode;
  return ref
      .watch(userPlansRepositoryProvider)
      .getUserPlans(language: languageCode);
});

final userPlanProgressDetailsFutureProvider =
    FutureProvider.autoDispose.family<List<PlanProgressModel>, String>((ref, planId) {
      return ref
          .watch(userPlansRepositoryProvider)
          .getUserPlanProgressDetails(planId);
    });

final userPlanSubscribeFutureProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  planId,
) {
  return ref.watch(userPlansRepositoryProvider).subscribeToPlan(planId);
});

final userPlanUnsubscribeFutureProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  planId,
) {
  return ref.watch(userPlansRepositoryProvider).unenrollFromPlan(planId);
});

final completeTaskFutureProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  taskId,
) {
  return ref.watch(userPlansRepositoryProvider).completeTask(taskId);
});

final deleteTaskFutureProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  taskId,
) {
  return ref.watch(userPlansRepositoryProvider).deleteTask(taskId);
});

final completeSubTaskFutureProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  subTaskId,
) {
  return ref.watch(userPlansRepositoryProvider).completeSubTask(subTaskId);
});

// My plans with pagination provider
final myPlansPaginatedProvider =
    StateNotifierProvider<MyPlansNotifier, MyPlansState>((ref) {
      final repository = ref.watch(userPlansRepositoryProvider);
      final locale = ref.watch(localeProvider);
      return MyPlansNotifier(
        repository: repository,
        languageCode: locale.languageCode,
      );
    });

// User plan day content provider
final userPlanDayContentFutureProvider =
    FutureProvider.autoDispose.family<UserPlanDayDetailResponse, PlanDaysParams>((
      ref,
      params,
    ) {
      return ref
          .watch(userPlansRepositoryProvider)
          .getUserPlanDayContent(params.planId, params.dayNumber);
    });

/// Provider that fetches completion status for all days in a plan using bulk endpoint
/// Returns a Map where key is dayNumber and value is isCompleted status
///
/// This uses a single API call instead of N separate calls (N+1 problem fixed)
final userPlanDaysCompletionStatusProvider =
    FutureProvider.autoDispose.family<Map<int, bool>, String>((ref, planId) async {
      final repository = ref.read(userPlansRepositoryProvider);

      try {
        // Single API call to get all day completion statuses
        return await repository.getPlanDaysCompletionStatus(planId);
      } catch (e) {
        _logger.error('Error fetching plan days completion status', e);
        // Return empty map on error - UI will show all days as incomplete
        return {};
      }
    });
