import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/plans/exceptions/plan_exceptions.dart';
import 'package:flutter_pecha/features/plans/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_day_detail_response.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_list_response_model.dart';
import 'package:http/http.dart' as http;

class UserPlansRemoteDatasource {
  final String baseUrl = dotenv.env['BASE_API_URL']!;
  final http.Client client;

  UserPlansRemoteDatasource({required this.client});

  // get user plans by user id
  Future<UserPlanListResponseModel> fetchUserPlans({
    required String language,
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{'language': language};

      if (skip != null) {
        queryParams['skip'] = skip.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await client.get(
        Uri.parse(
          '$baseUrl/users/me/plans',
        ).replace(queryParameters: queryParams),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return UserPlanListResponseModel.fromJson(jsonData);
      } else {
        debugPrint('Failed to load user plans: ${response.statusCode}');
        throw Exception('Failed to load user plans: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchUserPlans: $e');
      throw Exception('Failed to load user plans: $e');
    }
  }

  //subscribe user to a plan
  Future<bool> subscribeToPlan(String planId) async {
    final uri = Uri.parse('$baseUrl/users/me/plans');
    final body = json.encode({'plan_id': planId});
    try {
      final response = await client.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        throw PlanApiException(
          'Failed to subscribe to plan',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    } on SocketException catch (e, stackTrace) {
      throw PlanApiException(
        'Network error while subscribing to plan',
        originalError: e,
        stackTrace: stackTrace,
      );
    } on PlanApiException {
      rethrow;
    } catch (e, stackTrace) {
      throw PlanOperationException(
        'subscribeToPlan',
        'Unexpected error during subscription',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  // get user plan progress details
  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/me/plans/$planId'),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return jsonData.map((json) => PlanProgressModel.fromJson(json)).toList()
            as List<PlanProgressModel>;
      } else {
        throw Exception(
          'Failed to load user plan progress details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load user plan progress details: $e');
    }
  }

  // fetch user plan day content or details
  Future<UserPlanDayDetailResponse> fetchUserPlanDayContent(
    String planId,
    int dayNumber,
  ) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/me/plan/$planId/days/$dayNumber'),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return UserPlanDayDetailResponse.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load user plan day content: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Failed to load user plan day content: $e');
      throw Exception('Failed to load user plan day content: $e');
    }
  }

  /// Fetch completion status for all days in a plan (bulk endpoint)
  /// Returns a map where key is dayNumber and value is isCompleted status
  Future<Map<int, bool>> fetchPlanDaysCompletionStatus(String planId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/me/plans/$planId/days/completion_status'),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded) as Map<String, dynamic>;

        // Convert string keys to int keys
        final Map<int, bool> completionStatus = {};
        jsonData.forEach((key, value) {
          final dayNumber = int.tryParse(key);
          if (dayNumber != null) {
            completionStatus[dayNumber] = value as bool;
          }
        });

        return completionStatus;
      } else {
        debugPrint(
          'Failed to load plan days completion status: ${response.statusCode}',
        );
        throw Exception(
          'Failed to load plan days completion status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching plan days completion status: $e');
      throw Exception('Failed to load plan days completion status: $e');
    }
  }

  // sub tasks completion post request
  Future<bool> completeSubTask(String subTaskId) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/sub-tasks/$subTaskId/complete');
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('Failed to complete sub task: $errorMessage');
        throw Exception('Failed to complete sub task: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Failed to complete sub task: $e');
      throw Exception('Failed to complete sub task: $e');
    }
  }

  // task completion post request
  Future<bool> completeTask(String taskId) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/tasks/$taskId/complete');
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('Failed to complete task: $errorMessage');
        throw Exception('Failed to complete task: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Failed to complete task: $e');
      throw Exception('Failed to complete task: $e');
    }
  }

  // delete task request
  Future<bool> deleteTask(String taskId) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/task/$taskId');
      final response = await client.delete(uri);

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('Failed to delete task: $errorMessage');
        throw Exception('Failed to delete task: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Failed to delete task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  // unenroll from plan request
  Future<bool> unenrollFromPlan(String planId) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/plans/$planId');
      final response = await client.delete(uri);

      if (response.statusCode == 204) {
        return true;
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('Failed to unenroll from plan: $errorMessage');
        throw Exception('Failed to unenroll from plan: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Failed to unenroll from plan: $e');
      throw Exception('Failed to unenroll from plan: $e');
    }
  }
}
