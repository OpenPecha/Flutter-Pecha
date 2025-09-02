import 'package:flutter_pecha/features/plans/data/datasource/tasks_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/data/repositories/tasks_repository.dart';
import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(
    tasksRemoteDatasource: TasksRemoteDatasource(client: http.Client()),
  );
});

final tasksByPlanItemIdFutureProvider =
    FutureProvider.family<List<PlanTasksModel>, String>((ref, planItemId) {
      return ref
          .watch(tasksRepositoryProvider)
          .getTasksByPlanItemId(planItemId);
    });

final taskByIdFutureProvider = FutureProvider.family<PlanTasksModel, String>((
  ref,
  id,
) {
  return ref.watch(tasksRepositoryProvider).getTaskById(id);
});
