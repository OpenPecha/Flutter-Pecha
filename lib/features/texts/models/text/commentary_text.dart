class CommentaryText {
  final String id;
  final String? pechaTextId;
  final String title;
  final String? language;
  final String groupId;
  final String type;
  final String? summary;
  final bool isPublished;
  final DateTime createdDate;
  final DateTime updatedDate;
  final DateTime publishedDate;
  final String publishedBy;
  final List<String>? categories;
  final int? views;
  final List<String>? likes;
  final String? sourceLink;
  final int? ranking;
  final String? license;

  const CommentaryText({
    required this.id,
    this.pechaTextId,
    required this.title,
    required this.language,
    required this.type,
    required this.groupId,
    this.summary,
    required this.isPublished,
    required this.createdDate,
    required this.updatedDate,
    required this.publishedDate,
    required this.publishedBy,
    this.categories,
    this.views,
    this.likes,
    this.sourceLink,
    this.ranking,
    this.license,
  });

  factory CommentaryText.fromJson(Map<String, dynamic> json) {
    return CommentaryText(
      id: json['id'] as String,
      pechaTextId: json['pecha_text_id'] as String?,
      title: json['title'] as String,
      language: json['language'] as String?,
      type: json['type'] as String,
      groupId: json['group_id'] as String,
      summary: json['summary'] as String?,
      isPublished: json['is_published'] as bool,
      createdDate: DateTime.parse(json['created_date'] as String),
      updatedDate: DateTime.parse(json['updated_date'] as String),
      publishedDate: DateTime.parse(json['published_date'] as String),
      publishedBy: json['published_by'] as String,
      categories:
          (json['categories'] as List?)?.map((e) => e as String).toList(),
      views: json['views'] as int?,
      likes: (json['likes'] as List?)?.map((e) => e as String).toList(),
      sourceLink: json['source_link'] as String?,
      ranking: json['ranking'] as int?,
      license: json['license'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pecha_text_id': pechaTextId,
      'title': title,
      'language': language,
      'type': type,
      'group_id': groupId,
      'summary': summary,
      'is_published': isPublished,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
      'published_date': publishedDate.toIso8601String(),
      'published_by': publishedBy,
      'categories': categories,
      'views': views,
      'likes': likes,
      'source_link': sourceLink,
      'ranking': ranking,
      'license': license,
    };
  }
}
