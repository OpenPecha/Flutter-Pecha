enum DifficultyLevel { beginner, intermediate, advanced }

enum PlanStatus { draft, published, archived, inactive }

enum LanguageCode { en, bo, zh }

class PlansModel {
  final String id;
  final String title;
  final String? description;
  final String authorId;
  final LanguageCode language;
  final DifficultyLevel difficultyLevel;
  final int durationDays;
  final int? estimatedDailyMinutes;
  final List<String> tags; // Now required with default empty array
  final PlanStatus status;
  final bool featured;
  final String? imageUrl;
  // Audit trail fields
  final String createdBy; // Email of creator - required
  final String? updatedBy; // Email of last updater
  final String? deletedBy; // Email of deleter
  final DateTime? deletedAt; // Soft delete timestamp

  final DateTime createdAt;
  final DateTime updatedAt;

  PlansModel({
    required this.id,
    required this.title,
    this.description,
    required this.authorId,
    required this.language,
    required this.difficultyLevel,
    required this.durationDays,
    this.estimatedDailyMinutes,
    this.tags = const [],
    this.status = PlanStatus.draft,
    this.featured = false,
    this.imageUrl,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlansModel.fromJson(Map<String, dynamic> json) {
    return PlansModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      authorId: json['author_id'] as String,
      language: LanguageCode.values.byName(json['language'] as String),
      difficultyLevel: DifficultyLevel.values.byName(
        json['difficulty_level'] as String,
      ),
      durationDays: json['duration_days'] as int,
      estimatedDailyMinutes: json['estimated_daily_minutes'] as int?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      status: PlanStatus.values.byName(
        (json['status'] as String).toLowerCase(),
      ),
      featured: json['featured'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
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
      'title': title,
      'description': description,
      'author_id': authorId,
      'language': language.name,
      'difficulty_level': difficultyLevel.name,
      'duration_days': durationDays,
      'estimated_daily_minutes': estimatedDailyMinutes,
      'tags': tags,
      'status': status.name.toUpperCase(),
      'featured': featured,
      'image_url': imageUrl,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_by': deletedBy,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this plan with optional field updates
  PlansModel copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    LanguageCode? language,
    DifficultyLevel? difficultyLevel,
    int? durationDays,
    int? estimatedDailyMinutes,
    List<String>? tags,
    PlanStatus? status,
    bool? featured,
    String? imageUrl,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlansModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      language: language ?? this.language,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      durationDays: durationDays ?? this.durationDays,
      estimatedDailyMinutes:
          estimatedDailyMinutes ?? this.estimatedDailyMinutes,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      featured: featured ?? this.featured,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this plan is soft deleted
  bool get isDeleted => deletedAt != null;

  /// Check if this plan is published and active
  bool get isActive => status == PlanStatus.published && !isDeleted;

  /// Check if this plan is a draft
  bool get isDraft => status == PlanStatus.draft;

  /// Get display name for difficulty level
  String get difficultyDisplayName {
    switch (difficultyLevel) {
      case DifficultyLevel.beginner:
        return 'Beginner';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.advanced:
        return 'Advanced';
    }
  }

  /// Get display name for language
  String get languageDisplayName {
    switch (language) {
      case LanguageCode.en:
        return 'English';
      case LanguageCode.bo:
        return 'Tibetan';
      case LanguageCode.zh:
        return 'Chinese';
    }
  }

  /// Get display name for status
  String get statusDisplayName {
    switch (status) {
      case PlanStatus.draft:
        return 'Draft';
      case PlanStatus.published:
        return 'Published';
      case PlanStatus.archived:
        return 'Archived';
      case PlanStatus.inactive:
        return 'Inactive';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlansModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PlansModel(id: $id, title: $title, status: $status, featured: $featured)';
  }
}
