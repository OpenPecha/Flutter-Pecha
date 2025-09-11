import 'package:flutter_pecha/features/plans/data/datasource/plan_days_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/models/plan_days_model.dart';

class PlanDaysRepository {
  final PlanDaysRemoteDatasource planDaysRemoteDatasource;

  PlanDaysRepository({required this.planDaysRemoteDatasource});

  Future<List<PlanDaysModel>> getPlanDaysByPlanId(String planId) async {
    try {
      return await planDaysRemoteDatasource.getPlanDaysByPlanId(planId);
    } catch (e) {
      throw Exception('Failed to load plan items: $e');
    }
  }
}
