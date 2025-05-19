class Term {
  final String id;
  final String title;
  final String description;
  final String slug;
  final bool hasChild;

  Term({
    required this.id,
    required this.title,
    required this.description,
    required this.slug,
    required this.hasChild,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      slug: json['slug'] as String,
      hasChild: json['has_child'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'slug': slug,
      'has_child': hasChild,
    };
  }
}
