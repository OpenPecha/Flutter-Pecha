import 'package:flutter_pecha/features/texts/models/commentary/parent_segment.dart';
import 'package:flutter_pecha/features/texts/models/commentary/segment_commentary.dart';

class SegmentCommentaryResponse {
  final ParentSegment parentSegment;
  final List<SegmentCommentary> commentaries;

  SegmentCommentaryResponse({
    required this.parentSegment,
    required this.commentaries,
  });

  factory SegmentCommentaryResponse.fromJson(Map<String, dynamic> json) {
    return SegmentCommentaryResponse(
      parentSegment: ParentSegment.fromJson(json['parent_segment']),
      commentaries:
          (json['commentaries'] as List)
              .map((json) => SegmentCommentary.fromJson(json))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_segment': parentSegment.toJson(),
      'commentaries': commentaries.map((e) => e.toJson()).toList(),
    };
  }
}
