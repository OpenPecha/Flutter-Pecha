class TextDetail {
  final String id;
  final String title;
  final String language;
  final String type;
  final String groupId;
  final bool isPublished;
  final String createdDate;
  final String updatedDate;
  final String publishedDate;
  final String publishedBy;
  final List<String> categories;
  final String? parentId;

  TextDetail({
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
    required this.categories,
    this.parentId,
  });

  factory TextDetail.fromJson(Map<String, dynamic> json) {
    return TextDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      type: json['type'] as String,
      groupId: json['group_id'] as String,
      isPublished: json['is_published'] as bool,
      createdDate: json['created_date'] as String,
      updatedDate: json['updated_date'] as String,
      publishedDate: json['published_date'] as String,
      publishedBy: json['published_by'] as String,
      categories: (json['categories'] as List).map((e) => e as String).toList(),
      parentId: json['parent_id'] as String?,
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
      'created_date': createdDate,
      'updated_date': updatedDate,
      'published_date': publishedDate,
      'published_by': publishedBy,
      'categories': categories,
      'parent_id': parentId,
    };
  }
}
