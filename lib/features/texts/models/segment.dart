import 'package:flutter_pecha/features/texts/models/translation.dart';

class Segment {
  final String segmentId;
  final int segmentNumber;
  final String? content;
  final Translation? translation;

  const Segment({
    required this.segmentId,
    required this.segmentNumber,
    this.content,
    this.translation,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      segmentId: json['segment_id'] as String,
      segmentNumber: json['segment_number'] as int,
      content: json['content'] as String?,
      translation:
          json['translation'] != null
              ? Translation.fromJson(
                json['translation'] as Map<String, dynamic>,
              )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segment_id': segmentId,
      'segment_number': segmentNumber,
      'content': content ?? '',
      'translation': translation?.toJson(),
    };
  }
}
