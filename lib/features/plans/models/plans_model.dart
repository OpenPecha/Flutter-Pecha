import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';

enum DifficultyLevel { beginner, intermediate, advanced }

class PlansModel {
  final String id;
  final String title;
  final String description;
  final String language;
  final String? difficultyLevel;
  final String? imageUrl;
  final int? totalDays;
  final List<String>? tags;
  final AuthorDtoModel? author;

  PlansModel({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    this.difficultyLevel,
    this.imageUrl,
    this.totalDays,
    this.tags,
    this.author,
  });

  factory PlansModel.fromJson(Map<String, dynamic> json) {
    return PlansModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      difficultyLevel: json['difficulty_level'] as String?,
      imageUrl: json['image_url'] as String?,
      totalDays: json['total_days'] as int?,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      author:
          json['author'] != null
              ? AuthorDtoModel.fromJson(json['author'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'difficulty_level': difficultyLevel,
      'image_url': imageUrl,
      'total_days': totalDays ?? 0,
      'tags': tags,
    };
  }

  /// Create a copy of this plan with optional field updates
  PlansModel copyWith({
    String? id,
    String? title,
    String? description,
    String? language,
    String? difficultyLevel,
    String? imageUrl,
    int? totalDays = 0,
    List<String>? tags,
  }) {
    return PlansModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      language: language ?? this.language,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      imageUrl: imageUrl ?? this.imageUrl,
      totalDays: totalDays ?? this.totalDays,
      tags: tags ?? this.tags,
    );
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
    return 'PlansModel(id: $id, title: $title, language: $language, totalDays: $totalDays)';
  }
}
