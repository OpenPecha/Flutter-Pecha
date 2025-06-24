class TextIndex {
  final String textId;
  final String language;
  final String title;
  final DateTime publishedDate;

  TextIndex({
    required this.textId,
    required this.language,
    required this.title,
    required this.publishedDate,
  });

  factory TextIndex.fromJson(Map<String, dynamic> json) {
    return TextIndex(
      textId: json['text_id'],
      language: json['language'],
      title: json['title'],
      publishedDate: DateTime.parse(json['published_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'language': language,
      'title': title,
      'published_date': publishedDate.toIso8601String(),
    };
  }
}
