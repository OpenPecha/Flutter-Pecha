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

  /// Subscribe user to a plan
  /// Throws [Exception] if enrollment fails
  Future<bool> subscribeToPlan(String planId) async {
    try {
      return await userPlansRemoteDatasource.subscribeToPlan(planId);
    } catch (e) {
      throw Exception('Repository: Failed to subscribe to plan - $e');
    }
  }

  /// Get user plan progress details
  /// Throws [Exception] if fetching fails
  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    try {
      return await userPlansRemoteDatasource.getUserPlanProgressDetails(planId);
    } catch (e) {
      throw Exception('Repository: Failed to get plan progress details - $e');
    }
  }

  /// Get user plan day content
  /// Throws [Exception] if fetching fails
  Future<UserPlanDayDetailResponse> getUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    try {
      return await userPlansRemoteDatasource.fetchUserPlanDayContent(
        planId,
        dayNumber,
      );
    } catch (e) {
      throw Exception('Repository: Failed to get plan day content - $e');
    }
  }

  /// Get completion status for all days in a plan using bulk endpoint
  /// This replaces the N+1 query pattern with a single API call
  /// Throws [Exception] if fetching fails
  Future<Map<int, bool>> getPlanDaysCompletionStatus(String planId) async {
    try {
      return await userPlansRemoteDatasource.fetchPlanDaysCompletionStatus(
        planId,
      );
    } catch (e) {
      throw Exception(
        'Repository: Failed to get plan days completion status - $e',
      );
    }
  }

  /// Mark a subtask as complete
  /// Throws [Exception] if operation fails
  Future<bool> completeSubTask(String subTaskId) async {
    try {
      return await userPlansRemoteDatasource.completeSubTask(subTaskId);
    } catch (e) {
      throw Exception('Repository: Failed to complete subtask - $e');
    }
  }

  /// Mark a task as complete
  /// Throws [Exception] if operation fails
  Future<bool> completeTask(String taskId) async {
    try {
      return await userPlansRemoteDatasource.completeTask(taskId);
    } catch (e) {
      throw Exception('Repository: Failed to complete task - $e');
    }
  }

  /// Delete/uncomplete a task
  /// Throws [Exception] if operation fails
  Future<bool> deleteTask(String taskId) async {
    try {
      return await userPlansRemoteDatasource.deleteTask(taskId);
    } catch (e) {
      throw Exception('Repository: Failed to delete task - $e');
    }
  }

  /// Unenroll user from a plan
  /// Throws [Exception] if operation fails
  Future<bool> unenrollFromPlan(String planId) async {
    try {
      return await userPlansRemoteDatasource.unenrollFromPlan(planId);
    } catch (e) {
      throw Exception('Repository: Failed to unenroll from plan - $e');
    }
  }
}
