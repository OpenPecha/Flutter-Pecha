import 'package:equatable/equatable.dart';

enum PoemStatus {
  draft,
  published;

  factory PoemStatus.fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'PUBLISHED':
        return PoemStatus.published;
      default:
        return PoemStatus.draft;
    }
  }
}

class Poem extends Equatable {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String? chapterName;
  final String? imageUrl;
  final PoemStatus status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Poem({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    this.chapterName,
    this.imageUrl,
    this.status = PoemStatus.draft,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    content,
    authorName,
    chapterName,
    imageUrl,
    status,
    publishedAt,
    createdAt,
    updatedAt,
  ];
}
