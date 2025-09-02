import 'package:flutter_pecha/features/plans/data/datasource/tasks_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';

class TasksRepository {
  final TasksRemoteDatasource tasksRemoteDatasource;

  TasksRepository({required this.tasksRemoteDatasource});

  Future<List<PlanTasksModel>> getTasksByPlanItemId(String planItemId) async {
    try {
      return await tasksRemoteDatasource.getTasksByPlanItemId(planItemId);
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<PlanTasksModel> getTaskById(String id) async {
    try {
      return await tasksRemoteDatasource.getTaskById(id);
    } catch (e) {
      throw Exception('Failed to load task: $e');
    }
  }
}
