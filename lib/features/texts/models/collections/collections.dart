class Collections {
  final String id;
  final String title;
  final String description;
  final String language;
  final String slug;
  final bool hasChild;

  Collections({
    required this.id,
    required this.title,
    required this.description,
    required this.language,
    required this.slug,
    required this.hasChild,
  });

  factory Collections.fromJson(Map<String, dynamic> json) {
    return Collections(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      slug: json['slug'] as String,
      hasChild: json['has_child'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'slug': slug,
      'has_child': hasChild,
    };
  }
}
