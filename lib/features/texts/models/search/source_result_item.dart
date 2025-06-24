import 'package:flutter_pecha/features/texts/models/search/segment_match.dart';
import 'package:flutter_pecha/features/texts/models/search/text_index.dart';

class SourceResultItem {
  final TextIndex text;
  final List<SegmentMatch> segmentMatches;

  SourceResultItem({required this.text, required this.segmentMatches});

  factory SourceResultItem.fromJson(Map<String, dynamic> json) {
    return SourceResultItem(
      text: TextIndex.fromJson(json['text']),
      segmentMatches:
          (json['segment_match'] as List)
              .map((e) => SegmentMatch.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text.toJson(),
      'segment_match': segmentMatches.map((e) => e.toJson()).toList(),
    };
  }
}
