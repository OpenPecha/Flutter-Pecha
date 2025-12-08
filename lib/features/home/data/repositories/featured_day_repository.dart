import 'package:flutter_pecha/features/home/data/datasource/featured_day_remote_datasource.dart';
import 'package:flutter_pecha/features/plans/models/response/featured_day_response.dart';

class FeaturedDayRepository {
  final FeaturedDayRemoteDatasource featuredDayRemoteDatasource;

  FeaturedDayRepository({required this.featuredDayRemoteDatasource});

  Future<FeaturedDayResponse> getFeaturedDay({String? language}) async {
    try {
      return await featuredDayRemoteDatasource.fetchFeaturedDay(
        language: language,
      );
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }

  /// Convert FeaturedDayResponse tasks to List of FeaturedDayTask
  List<FeaturedDayTask> mapToFeaturedDayTasks(FeaturedDayResponse response) {
    return response.tasks.map((task) {
      return FeaturedDayTask(
        id: task.id,
        title: task.title,
        estimatedTime: task.estimatedTime,
        displayOrder: task.displayOrder,
        subtasks: task.subtasks,
      );
    }).toList();
  }
}
