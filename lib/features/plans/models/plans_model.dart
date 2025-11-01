import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';

enum DifficultyLevel { beginner, intermediate, advanced }

enum PlanStatus { draft, published, archived, inactive }

enum LanguageCode { en, bo, zh }

class PlansModel {
  final String id;
  final String title;
  final String description;
  final String language;
  final String? difficultyLevel;
  final String? imageUrl;
  final int totalDays;
  final PlanStatus status;
  final int subscriptionCount;
  final AuthorDtoModel? author;

  PlansModel({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    this.difficultyLevel,
    this.imageUrl,
    required this.totalDays,
    this.status = PlanStatus.draft,
    required this.subscriptionCount,
    this.author,
  });

  factory PlansModel.fromJson(Map<String, dynamic> json) {
    return PlansModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      difficultyLevel: json['difficulty_level'] as String?,
      totalDays: json['total_days'] as int,
      status: PlanStatus.values.byName(
        (json['status'] as String).toLowerCase(),
      ),
      subscriptionCount: json['subscription_count'] as int,
      author:
          json['author'] != null
              ? AuthorDtoModel.fromJson(json['author'])
              : null,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'difficulty_level': difficultyLevel,
      'total_days': totalDays,
      'status': status.name.toUpperCase(),
      'subscription_count': subscriptionCount,
      'author': author?.toJson(),
      'image_url': imageUrl,
    };
  }

  /// Create a copy of this plan with optional field updates
  PlansModel copyWith({
    String? id,
    String? title,
    String? description,
    String? language,
    String? difficultyLevel,
    int? totalDays,
    PlanStatus? status,
    bool? featured,
    String? imageUrl,
    int? subscriptionCount,
    AuthorDtoModel? author,
  }) {
    return PlansModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      language: language ?? this.language,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      totalDays: totalDays ?? this.totalDays,
      status: status ?? this.status,
      subscriptionCount: subscriptionCount ?? this.subscriptionCount,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Check if this plan is soft deleted
  // bool get isDeleted => deletedAt != null;

  /// Check if this plan is published and active
  // bool get isActive => status == PlanStatus.published && !isDeleted;

  /// Check if this plan is a draft
  bool get isDraft => status == PlanStatus.draft;

  /// Get display name for difficulty level
  // String get difficultyDisplayName {
  //   switch (difficultyLevel) {
  //     case DifficultyLevel.beginner:
  //       return 'Beginner';
  //     case DifficultyLevel.intermediate:
  //       return 'Intermediate';
  //     case DifficultyLevel.advanced:
  //       return 'Advanced';
  //     default:
  //       return 'Unknown';
  //   }
  // }

  /// Get display name for language
  // String get languageDisplayName {
  //   switch (language) {
  //     case LanguageCode.en:
  //       return 'English';
  //     case LanguageCode.bo:
  //       return 'Tibetan';
  //     case LanguageCode.zh:
  //       return 'Chinese';
  //     default:
  //       return 'Unknown';
  //   }
  // }

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
    return 'PlansModel(id: $id, title: $title, status: $status, author: $author)';
  }
}
