import 'package:flutter_pecha/features/plans/models/plans_model.dart';

class PlanProgressModel {
  final String id;
  final String userId;
  final String planId;
  final PlansModel? plan;
  final DateTime startedAt;
  final int? streakCount;
  final int? longestStreak;
  final String? status;
  final bool? isCompleted;
  final DateTime? completedAt;
  final DateTime? createdAt;

  PlanProgressModel({
    required this.id,
    required this.userId,
    required this.planId,
    this.plan,
    required this.startedAt,
    this.streakCount,
    this.longestStreak,
    this.status,
    this.isCompleted,
    this.completedAt,
    this.createdAt,
  });

  factory PlanProgressModel.fromJson(Map<String, dynamic> json) {
    return PlanProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      plan: json['plan'] != null ? PlansModel.fromJson(json['plan']) : null,
      startedAt: DateTime.parse(json['started_at'] as String),
      streakCount: json['streak_count'] as int?,
      longestStreak: json['longest_streak'] as int?,
      status: json['status'] as String?,
      isCompleted: json['is_completed'] as bool?,
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'plan': plan?.toJson(),
      'started_at': startedAt.toIso8601String(),
      'streak_count': streakCount,
      'longest_streak': longestStreak,
      'status': status,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
