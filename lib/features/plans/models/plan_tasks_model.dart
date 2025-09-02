enum ContentType { text, audio, video, image, sourceReference }

class PlanTasksModel {
  final String id;
  final String planItemId;
  final String? title; // Made nullable as per schema
  final ContentType contentType; // Fixed typo from contentTye
  final String? content; // Made nullable as per schema
  final int displayOrder;
  final int? estimatedTime; // Changed to int? (minutes) as per schema
  final bool isRequired;
  // Audit trail fields
  final String createdBy; // Email of creator - required
  final String? updatedBy; // Email of last updater
  final String? deletedBy; // Email of deleter
  final DateTime? deletedAt; // Soft delete timestamp
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanTasksModel({
    required this.id,
    required this.planItemId,
    this.title,
    required this.contentType,
    this.content,
    required this.displayOrder,
    this.estimatedTime,
    this.isRequired = true,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanTasksModel.fromJson(Map<String, dynamic> json) {
    return PlanTasksModel(
      id: json['id'] as String,
      planItemId: json['plan_item_id'] as String,
      title: json['title'] as String?,
      contentType: ContentType.values.byName(json['content_type'] as String),
      content: json['content'] as String?,
      displayOrder: json['display_order'] as int,
      estimatedTime: json['estimated_time'] as int?,
      isRequired: json['is_required'] as bool? ?? true,
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
      'plan_item_id': planItemId,
      'title': title,
      'content_type': contentType.name,
      'content': content,
      'display_order': displayOrder,
      'estimated_time': estimatedTime,
      'is_required': isRequired,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this plan task with optional field updates
  PlanTasksModel copyWith({
    String? id,
    String? planItemId,
    String? title,
    ContentType? contentType,
    String? content,
    int? displayOrder,
    int? estimatedTime,
    bool? isRequired,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanTasksModel(
      id: id ?? this.id,
      planItemId: planItemId ?? this.planItemId,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      displayOrder: displayOrder ?? this.displayOrder,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isRequired: isRequired ?? this.isRequired,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this plan task is soft deleted
  bool get isDeleted => deletedAt != null;

  /// Check if this plan task is active (not deleted)
  bool get isActive => !isDeleted;

  /// Check if this task is optional (not required)
  bool get isOptional => !isRequired;

  /// Get display name for content type
  String get contentTypeDisplayName {
    switch (contentType) {
      case ContentType.text:
        return 'Text';
      case ContentType.audio:
        return 'Audio';
      case ContentType.video:
        return 'Video';
      case ContentType.image:
        return 'Image';
      case ContentType.sourceReference:
        return 'Source Reference';
    }
  }

  /// Get estimated time in a human-readable format
  String get estimatedTimeDisplay {
    if (estimatedTime == null) return 'No time estimate';
    final minutes = estimatedTime!;
    if (minutes < 60) {
      return '$minutes min${minutes == 1 ? '' : 's'}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hour${hours == 1 ? '' : 's'}';
      } else {
        return '$hours hour${hours == 1 ? '' : 's'} $remainingMinutes min${remainingMinutes == 1 ? '' : 's'}';
      }
    }
  }

  /// Get task display title with fallback
  String get displayTitle => title ?? 'Untitled Task';

  /// Check if task has content
  bool get hasContent => content != null && content!.isNotEmpty;

  /// Check if task has title
  bool get hasTitle => title != null && title!.isNotEmpty;

  /// Validate that display order is positive
  bool get isValidDisplayOrder => displayOrder > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanTasksModel &&
        other.id == id &&
        other.planItemId == planItemId &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode => Object.hash(id, planItemId, displayOrder);

  @override
  String toString() {
    return 'PlanTasksModel(id: $id, planItemId: $planItemId, title: $displayTitle, contentType: ${contentType.name}, displayOrder: $displayOrder, isRequired: $isRequired, isDeleted: $isDeleted)';
  }
}
