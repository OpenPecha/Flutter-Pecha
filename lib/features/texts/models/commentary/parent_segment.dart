class ParentSegment {
  final String segmentId;
  final String content;

  ParentSegment({required this.segmentId, required this.content});

  factory ParentSegment.fromJson(Map<String, dynamic> json) {
    return ParentSegment(
      segmentId: json['segment_id'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'segment_id': segmentId, 'content': content};
  }
}
