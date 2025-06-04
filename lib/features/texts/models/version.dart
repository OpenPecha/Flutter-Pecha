class Version {
  final String id;
  final String title;
  final String? parentId;
  final int? priority;
  final String language;
  final String type;
  final String groupId;
  final List<String> tableOfContents;
  final bool isPublished;
  final String createdDate;
  final String updatedDate;
  final String publishedDate;
  final String publishedBy;

  const Version({
    required this.id,
    required this.title,
    this.parentId,
    this.priority,
    required this.language,
    required this.type,
    required this.groupId,
    required this.tableOfContents,
    required this.isPublished,
    required this.createdDate,
    required this.updatedDate,
    required this.publishedDate,
    required this.publishedBy,
  });

  factory Version.fromJson(Map<String, dynamic> json) {
    return Version(
      id: json['id'] as String,
      title: json['title'] as String,
      parentId: json['parent_id'] as String?,
      priority: json['priority'] as int?,
      language: json['language'] as String,
      type: json['type'] as String,
      groupId: json['group_id'] as String,
      tableOfContents:
          (json['table_of_contents'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      isPublished: json['is_published'] as bool,
      createdDate: json['created_date'] as String,
      updatedDate: json['updated_date'] as String,
      publishedDate: json['published_date'] as String,
      publishedBy: json['published_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'parent_id': parentId,
      'priority': priority,
      'language': language,
      'type': type,
      'group_id': groupId,
      'table_of_contents': tableOfContents,
      'is_published': isPublished,
      'created_date': createdDate,
      'updated_date': updatedDate,
      'published_date': publishedDate,
      'published_by': publishedBy,
    };
  }
}
