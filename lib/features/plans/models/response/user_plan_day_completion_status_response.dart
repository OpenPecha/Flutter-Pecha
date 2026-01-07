class UserPlanDayCompletionStatus {
  final int dayNumber;
  final bool isCompleted;

  UserPlanDayCompletionStatus({
    required this.dayNumber,
    required this.isCompleted,
  });

  factory UserPlanDayCompletionStatus.fromJson(Map<String, dynamic> json) {
    return UserPlanDayCompletionStatus(
      dayNumber: json['day_number'] as int,
      isCompleted: json['is_completed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_number': dayNumber,
      'is_completed': isCompleted,
    };
  }
}

class UserPlanDayCompletionStatusResponse {
  final List<UserPlanDayCompletionStatus> days;

  UserPlanDayCompletionStatusResponse({required this.days});

  factory UserPlanDayCompletionStatusResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return UserPlanDayCompletionStatusResponse(
      days: (json['days'] as List<dynamic>)
          .map(
            (day) =>
                UserPlanDayCompletionStatus.fromJson(day as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days.map((e) => e.toJson()).toList(),
    };
  }

  /// Converts the response to a Map for easy lookup
  Map<int, bool> toCompletionStatusMap() {
    return {for (final day in days) day.dayNumber: day.isCompleted};
  }
}
