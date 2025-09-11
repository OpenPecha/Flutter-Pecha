enum ContentType { text, audio, video, image, sourceReference }

class PlanTasksModel {
  final String id;
  final String title;
  final String? description;
  final ContentType contentType;
  final String? content; // Made nullable as per schema
  final int? estimatedTime;
  final int? displayOrder;

  PlanTasksModel({
    required this.id,
    required this.title,
    this.description,
    required this.contentType,
    this.content,
    this.displayOrder,
    this.estimatedTime,
  });

  factory PlanTasksModel.fromJson(Map<String, dynamic> json) {
    return PlanTasksModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      contentType: ContentType.values.byName(json['content_type'] as String),
      content: json['content'] as String?,
      displayOrder: json['display_order'] as int?,
      estimatedTime: json['estimated_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content_type': contentType.name,
      'content': content,
      'display_order': displayOrder,
      'estimated_time': estimatedTime,
    };
  }

  /// Create a copy of this plan task with optional field updates
  PlanTasksModel copyWith({
    String? id,
    String? title,
    String? description,
    ContentType? contentType,
    String? content,
    int? displayOrder,
    int? estimatedTime,
  }) {
    return PlanTasksModel(
      id: id ?? this.id,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      displayOrder: displayOrder ?? this.displayOrder,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      description: description ?? this.description,
    );
  }

  /// Check if this plan task is soft deleted
  // bool get isDeleted => deletedAt != null;

  /// Check if this plan task is active (not deleted)
  // bool get isActive => !isDeleted;

  /// Check if this task is optional (not required)
  // bool get isOptional => !isRequired;

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
  String get displayTitle => title;

  /// Check if task has content
  bool get hasContent => content != null && content!.isNotEmpty;

  /// Check if task has title
  bool get hasTitle => title.isNotEmpty;

  /// Validate that display order is positive
  bool get isValidDisplayOrder => displayOrder != null && displayOrder! > 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanTasksModel &&
        other.id == id &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode => Object.hash(id, displayOrder);

  @override
  String toString() {
    return 'PlanTasksModel(id: $id, title: $displayTitle, contentType: ${contentType.name}, displayOrder: $displayOrder)';
  }
}
