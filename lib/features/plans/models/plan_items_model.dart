class PlanItemsModel {
  final String id;
  final String planId;
  final int dayNumber;
  // Audit trail fields
  final String createdBy; // Email of creator - required
  final String? updatedBy; // Email of last updater
  final String? deletedBy; // Email of deleter
  final DateTime? deletedAt; // Soft delete timestamp
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanItemsModel({
    required this.id,
    required this.planId,
    required this.dayNumber,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanItemsModel.fromJson(Map<String, dynamic> json) {
    return PlanItemsModel(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      dayNumber: json['day_number'] as int,
      createdBy: json['created_by'] as String,
      updatedBy: json['updated_by'] as String?,
      deletedBy: json['deleted_by'] as String?,
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_number': dayNumber,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this plan item with optional field updates
  PlanItemsModel copyWith({
    String? id,
    String? planId,
    int? dayNumber,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanItemsModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayNumber: dayNumber ?? this.dayNumber,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this plan item is soft deleted
  bool get isDeleted => deletedAt != null;

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
    return other is PlanItemsModel &&
        other.id == id &&
        other.planId == planId &&
        other.dayNumber == dayNumber;
  }

  @override
  int get hashCode => Object.hash(id, planId, dayNumber);

  @override
  String toString() {
    return 'PlanItemsModel(id: $id, planId: $planId, dayNumber: $dayNumber, isDeleted: $isDeleted)';
  }
}
