import 'package:flutter_pecha/features/plans/data/datasource/user_plans_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_list_response_model.dart';

class UserPlansRepository {
  final UserPlansRemoteDatasource userPlansRemoteDatasource;

  UserPlansRepository({required this.userPlansRemoteDatasource});

  Future<UserPlanListResponseModel> getUserPlans({
    required String language,
    int? skip,
    int? limit,
  }) async {
    return await userPlansRemoteDatasource.fetchUserPlans(
      language: language,
      skip: skip,
      limit: limit,
    );
  }

  Future<bool> subscribeToPlan(String planId) async {
    return await userPlansRemoteDatasource.subscribeToPlan(planId);
  }

  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    return await userPlansRemoteDatasource.getUserPlanProgressDetails(planId);
  }

  Future<UserPlanDayDetailResponse> getUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    return await userPlansRemoteDatasource.fetchUserPlanDayContent(
      planId,
      dayNumber,
    );
  }

  Future<bool> completeSubTask(String subTaskId) async {
    return await userPlansRemoteDatasource.completeSubTask(subTaskId);
  }

  Future<bool> completeTask(String taskId) async {
    return await userPlansRemoteDatasource.completeTask(taskId);
  }

  Future<bool> deleteTask(String taskId) async {
    return await userPlansRemoteDatasource.deleteTask(taskId);
  }
}
