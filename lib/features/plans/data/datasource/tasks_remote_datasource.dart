import 'dart:convert';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';
import 'package:http/http.dart' as http;

class TasksRemoteDatasource {
  final http.Client client;
  final String baseUrl =
      'https://your-api-base-url.com'; // Replace with your actual API URL

  TasksRemoteDatasource({required this.client});

  // Get tasks by plan item ID
  Future<List<PlanTasksModel>> getTasksByPlanItemId(String planItemId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plan-items/$planItemId/tasks'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => PlanTasksModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  // Get task by ID
  Future<PlanTasksModel> getTaskById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlanTasksModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load task: $e');
    }
  }

  // Update task
  Future<PlanTasksModel> updateTask(String id, PlanTasksModel task) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlanTasksModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }
}
