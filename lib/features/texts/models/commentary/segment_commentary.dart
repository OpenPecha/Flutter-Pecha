class SegmentCommentary {
  final String segmentId;
  final String textId;
  final String title;
  final String content;
  final String language;
  final int count;

  SegmentCommentary({
    required this.segmentId,
    required this.textId,
    required this.title,
    required this.content,
    required this.language,
    required this.count,
  });

  factory SegmentCommentary.fromJson(Map<String, dynamic> json) {
    return SegmentCommentary(
      segmentId: json['segment_id'],
      textId: json['text_id'],
      title: json['title'],
      content: json['content'],
      language: json['language'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segment_id': segmentId,
      'text_id': textId,
      'title': title,
      'content': content,
      'language': language,
      'count': count,
    };
  }
}
