class SegmentCommentary {
  final String textId;
  final String title;
  final List<MappedSegmentDTO> segments;
  final String language;
  final int count;

  SegmentCommentary({
    required this.textId,
    required this.title,
    required this.segments,
    required this.language,
    required this.count,
  });

  factory SegmentCommentary.fromJson(Map<String, dynamic> json) {
    return SegmentCommentary(
      textId: json['text_id'],
      title: json['title'],
      segments:
          json['segments'] != null
              ? (json['segments'] as List<dynamic>)
                  .map(
                    (e) => MappedSegmentDTO.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : <MappedSegmentDTO>[],
      language: json['language'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'title': title,
      'segments': segments.map((e) => e.toJson()).toList(),
      'language': language,
      'count': count,
    };
  }
}

class MappedSegmentDTO {
  final String segmentId;
  final String content;

  MappedSegmentDTO({required this.segmentId, required this.content});

  factory MappedSegmentDTO.fromJson(Map<String, dynamic> json) {
    return MappedSegmentDTO(
      segmentId: json['segment_id'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'segment_id': segmentId, 'content': content};
  }
}
