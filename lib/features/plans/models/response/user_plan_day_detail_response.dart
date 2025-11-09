import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/features/plans/models/user/user_tasks_dto.dart';

class UserPlanDayDetailResponse {
  final String id;
  final int dayNumber;
  final List<UserTasksDto> tasks;
  final bool isCompleted;

  UserPlanDayDetailResponse({
    required this.id,
    required this.dayNumber,
    required this.tasks,
    required this.isCompleted,
  });

  factory UserPlanDayDetailResponse.fromJson(Map<String, dynamic> json) {
    return UserPlanDayDetailResponse(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      tasks:
          (json['tasks'] as List<dynamic>)
              .map(
                (task) => UserTasksDto.fromJson(task as Map<String, dynamic>),
              )
              .toList(),
      isCompleted: json['is_completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'is_completed': isCompleted,
    };
  }
}
