class Texts {
  final String id;
  final String title;
  final String language;
  final String type;
  final String groupId;
  final bool isPublished;
  final DateTime createdDate;
  final DateTime updatedDate;
  final DateTime publishedDate;
  final String publishedBy;

  const Texts({
    required this.id,
    required this.title,
    required this.language,
    required this.type,
    required this.groupId,
    required this.isPublished,
    required this.createdDate,
    required this.updatedDate,
    required this.publishedDate,
    required this.publishedBy,
  });

  factory Texts.fromJson(Map<String, dynamic> json) {
    return Texts(
      id: json['id'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      type: json['type'] as String,
      groupId: json['group_id'] as String,
      isPublished: json['is_published'] as bool,
      createdDate: DateTime.parse(json['created_date'] as String),
      updatedDate: DateTime.parse(json['updated_date'] as String),
      publishedDate: DateTime.parse(json['published_date'] as String),
      publishedBy: json['published_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'language': language,
      'type': type,
      'group_id': groupId,
      'is_published': isPublished,
      'created_date': createdDate.toIso8601String(),
      'updated_date': updatedDate.toIso8601String(),
      'published_date': publishedDate.toIso8601String(),
      'published_by': publishedBy,
    };
  }
}
