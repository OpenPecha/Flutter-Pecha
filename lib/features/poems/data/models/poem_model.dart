import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';

class PoemModel {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String? chapterName;
  final String? imageUrl;
  final String? status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PoemModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.chapterName,
    this.imageUrl,
    this.status,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PoemModel.fromJson(Map<String, dynamic> json) {
    return PoemModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      authorName: (json['author_name'] as String?) ?? '',
      chapterName: json['chapter_name'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String?,
      publishedAt: _parseDate(json['published_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Poem toEntity() {
    return Poem(
      id: id,
      title: title,
      content: content,
      authorName: authorName,
      chapterName: chapterName,
      imageUrl: imageUrl,
      status: PoemStatus.fromJson(status),
      publishedAt: publishedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
