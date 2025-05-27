class Segment {
  final String segmentId;
  final int segmentNumber;
  final String content;
  final String translation;

  const Segment({
    required this.segmentId,
    required this.segmentNumber,
    required this.content,
    required this.translation,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      segmentId: json['segment_id'] as String,
      segmentNumber: json['segment_number'] as int,
      content: json['content'] as String,
      translation: json['translation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segment_id': segmentId,
      'segment_number': segmentNumber,
      'content': content,
      'translation': translation,
    };
  }
}
