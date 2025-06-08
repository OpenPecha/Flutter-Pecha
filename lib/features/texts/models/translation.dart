class Translation {
  final String textId;
  final String language;
  final String content;

  Translation({
    required this.textId,
    required this.content,
    required this.language,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      textId: json['text_id'],
      content: json['content'],
      language: json['language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'text_id': textId, 'content': content, 'language': language};
  }
}
