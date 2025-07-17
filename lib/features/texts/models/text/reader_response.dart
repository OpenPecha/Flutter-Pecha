import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';

class ReaderResponse {
  final TextDetail textDetail;
  final Toc content;
   final int size;
  final String paginationDirection;
  final int currentSegmentPosition;
  final int totalSegments;

  ReaderResponse({
    required this.textDetail,
    required this.content,
    required this.size,
    required this.paginationDirection,
    required this.currentSegmentPosition,
    required this.totalSegments,
  });

  factory ReaderResponse.fromJson(Map<String, dynamic> json) {
    return ReaderResponse(
      textDetail: TextDetail.fromJson(json['text_detail']),
      content: Toc.fromJson(json['content']),
      size: json['size'],
      paginationDirection: json['pagination_direction'],
      currentSegmentPosition: json['current_segment_position'],
      totalSegments: json['total_segments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_detail': textDetail.toJson(),
      'content': content.toJson(),
      'size': size,
      'pagination_direction': paginationDirection,
      'current_segment_position': currentSegmentPosition,
      'total_segments': totalSegments,
    };
  }
}
