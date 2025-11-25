class MultilingualSourceResult {
  final TextIndex text;
  final List<MultilingualSegmentMatch> segmentMatches;

  MultilingualSourceResult({required this.text, required this.segmentMatches});

  factory MultilingualSourceResult.fromJson(Map<String, dynamic> json) {
    return MultilingualSourceResult(
      text: TextIndex.fromJson(json['text'] as Map<String, dynamic>),
      segmentMatches:
          json['segment_matches'] != null
              ? (json['segment_matches'] as List<dynamic>)
                  .map(
                    (e) => MultilingualSegmentMatch.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList()
              : <MultilingualSegmentMatch>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text.toJson(),
      'segment_matches': segmentMatches.map((e) => e.toJson()).toList(),
    };
  }
}

class TextIndex {
  final String textId;
  final String language;
  final String title;
  final String publishedDate;

  TextIndex({
    required this.textId,
    required this.language,
    required this.title,
    required this.publishedDate,
  });

  factory TextIndex.fromJson(Map<String, dynamic> json) {
    return TextIndex(
      textId: json['text_id'],
      language: json['language'],
      title: json['title'],
      publishedDate: json['published_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'language': language,
      'title': title,
      'published_date': publishedDate,
    };
  }
}

class MultilingualSegmentMatch {
  final String segmentId;
  final String content;
  final double relevanceScore;
  final String pechaSegmentId;

  MultilingualSegmentMatch({
    required this.segmentId,
    required this.content,
    required this.relevanceScore,
    required this.pechaSegmentId,
  });

  factory MultilingualSegmentMatch.fromJson(Map<String, dynamic> json) {
    return MultilingualSegmentMatch(
      segmentId: json['segment_id'],
      content: json['content'],
      relevanceScore: json['relevance_score'],
      pechaSegmentId: json['pecha_segment_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'segment_id': segmentId,
      'content': content,
      'relevance_score': relevanceScore,
      'pecha_segment_id': pechaSegmentId,
    };
  }
}
