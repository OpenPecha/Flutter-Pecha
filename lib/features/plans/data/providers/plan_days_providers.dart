import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/plan_days_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final planDaysRepositoryProvider = Provider<PlanDaysRepository>((ref) {
  return PlanDaysRepository(
    planDaysRemoteDatasource: PlanDaysRemoteDatasource(
      client: ref.watch(apiClientProvider),
    ),
  );
});

// Get plan days by plan id provider
final planDaysByPlanIdFutureProvider =
    FutureProvider.family<List<PlanDaysModel>, String>((ref, planId) {
      return ref.watch(planDaysRepositoryProvider).getPlanDaysByPlanId(planId);
    });

// Plan days params
class PlanDaysParams {
  final String planId;
  final int dayNumber;
  const PlanDaysParams({required this.planId, required this.dayNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanDaysParams &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          dayNumber == other.dayNumber;

  @override
  int get hashCode => planId.hashCode ^ dayNumber.hashCode;
}

// Get day content with tasks by plan id and day number
final planDayContentFutureProvider =
    FutureProvider.family<PlanDaysModel, PlanDaysParams>((ref, params) {
      return ref
          .watch(planDaysRepositoryProvider)
          .getDayContent(params.planId, params.dayNumber);
    });
