class SegmentMatch {
  final String segmentId;
  final String content;

  SegmentMatch({required this.segmentId, required this.content});

  factory SegmentMatch.fromJson(Map<String, dynamic> json) {
    return SegmentMatch(
      segmentId: json['segment_id'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'segment_id': segmentId, 'content': content};
  }
}
