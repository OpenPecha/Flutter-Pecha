import 'package:flutter_pecha/features/plans/models/plan_tasks_model.dart';

class PlanDaysModel {
  final String id;
  final int dayNumber;
  final String title;
  final List<PlanTasksModel>? tasks;

  PlanDaysModel({
    required this.id,
    required this.dayNumber,
    required this.title,
    this.tasks,
  });

  factory PlanDaysModel.fromJson(Map<String, dynamic> json) {
    return PlanDaysModel(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      title: json['title'] as String,
      tasks:
          json['tasks'] != null
              ? (json['tasks'] as List<dynamic>)
                  .map(
                    (e) => PlanTasksModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_number': dayNumber,
      'title': title,
      'tasks': tasks?.map((e) => e.toJson()).toList(),
    };
  }

  /// Create a copy of this plan item with optional field updates
  PlanDaysModel copyWith({
    String? id,
    int? dayNumber,
    String? title,
    List<PlanTasksModel>? tasks,
  }) {
    return PlanDaysModel(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      title: title ?? this.title,
      tasks: tasks ?? this.tasks,
    );
  }

  /// Check if this plan item is soft deleted
  bool get isDeleted => false;

  /// Check if this plan item is active (not deleted)
  bool get isActive => !isDeleted;

  /// Get a human-readable day label (e.g., "Day 1", "Day 2")
  String get dayLabel => 'Day $dayNumber';

  /// Check if this is the first day of the plan
  bool get isFirstDay => dayNumber == 1;

  /// Validate that day number is positive
  bool get isValidDayNumber => dayNumber > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanDaysModel &&
        other.id == id &&
        other.dayNumber == dayNumber;
  }

  @override
  int get hashCode => Object.hash(id, dayNumber);

  @override
  String toString() {
    return 'PlanDaysModel(id: $id, dayNumber: $dayNumber, isDeleted: $isDeleted)';
  }
}
