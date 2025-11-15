class RecitationTextModel {
  final String id;
  final String content;

  RecitationTextModel({required this.id, required this.content});

  factory RecitationTextModel.fromJson(Map<String, dynamic> json) {
    return RecitationTextModel(
      id: json['id'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'content': content};
  }
}

class RecitationSegmentModel {
  final Map<String, RecitationTextModel>? recitation;
  final Map<String, RecitationTextModel>? translations;
  final Map<String, RecitationTextModel>? transliterations;
  final Map<String, RecitationTextModel>? adaptations;

  RecitationSegmentModel({
    this.recitation,
    this.translations,
    this.transliterations,
    this.adaptations,
  });

  factory RecitationSegmentModel.fromJson(Map<String, dynamic> json) {
    Map<String, RecitationTextModel>? parseTextMap(Map<String, dynamic>? data) {
      if (data == null) return null;
      return data.map(
        (key, value) => MapEntry(
          key,
          RecitationTextModel.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    return RecitationSegmentModel(
      recitation:
          json['recitation'] != null
              ? parseTextMap(json['recitation'] as Map<String, dynamic>)
              : null,
      translations:
          json['translations'] != null
              ? parseTextMap(json['translations'] as Map<String, dynamic>)
              : null,
      transliterations:
          json['transliterations'] != null
              ? parseTextMap(json['transliterations'] as Map<String, dynamic>)
              : null,
      adaptations:
          json['adaptations'] != null
              ? parseTextMap(json['adaptations'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic>? textMapToJson(
      Map<String, RecitationTextModel>? data,
    ) {
      if (data == null) return null;
      return data.map((key, value) => MapEntry(key, value.toJson()));
    }

    return {
      if (recitation != null) 'recitation': textMapToJson(recitation),
      if (translations != null) 'translations': textMapToJson(translations),
      if (transliterations != null)
        'transliterations': textMapToJson(transliterations),
      if (adaptations != null) 'adaptations': textMapToJson(adaptations),
    };
  }
}

class RecitationContentModel {
  final String textId;
  final String title;
  final List<RecitationSegmentModel> segments;

  RecitationContentModel({
    required this.textId,
    required this.title,
    required this.segments,
  });

  factory RecitationContentModel.fromJson(Map<String, dynamic> json) {
    return RecitationContentModel(
      textId: json['text_id'] as String,
      title: json['title'] as String,
      segments:
          (json['segments'] as List<dynamic>)
              .map(
                (segment) => RecitationSegmentModel.fromJson(
                  segment as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_id': textId,
      'title': title,
      'segments': segments.map((segment) => segment.toJson()).toList(),
    };
  }

  RecitationContentModel copyWith({
    String? textId,
    String? title,
    List<RecitationSegmentModel>? segments,
  }) {
    return RecitationContentModel(
      textId: textId ?? this.textId,
      title: title ?? this.title,
      segments: segments ?? this.segments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecitationContentModel && other.textId == textId;
  }

  @override
  int get hashCode => textId.hashCode;

  @override
  String toString() {
    return 'RecitationContentModel(textId: $textId, title: $title, segments: ${segments.length})';
  }
}
