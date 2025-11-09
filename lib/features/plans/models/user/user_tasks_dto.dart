import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';

class UserTasksDto {
  final String id;
  final String title;
  final int? estimatedTime;
  final int displayOrder;
  final bool isCompleted;
  final List<UserSubtasksDto> subTasks;

  UserTasksDto({
    required this.id,
    required this.title,
    required this.estimatedTime,
    required this.displayOrder,
    required this.isCompleted,
    required this.subTasks,
  });

  factory UserTasksDto.fromJson(Map<String, dynamic> json) {
    return UserTasksDto(
      id: json['id'] as String,
      title: json['title'] as String,
      estimatedTime: json['estimated_time'] as int?,
      displayOrder: json['display_order'] as int,
      isCompleted: json['is_completed'] as bool,
      subTasks:
          (json['sub_tasks'] as List<dynamic>)
              .map(
                (subtask) =>
                    UserSubtasksDto.fromJson(subtask as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'estimated_time': estimatedTime,
      'display_order': displayOrder,
      'is_completed': isCompleted,
      'sub_tasks': subTasks.map((e) => e.toJson()).toList(),
    };
  }
}
