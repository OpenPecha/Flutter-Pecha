import 'package:flutter_pecha/features/texts/models/section.dart';

class Toc {
  final String id;
  final String textId;
  final List<Section> sections;

  Toc({required this.id, required this.textId, required this.sections});

  factory Toc.fromJson(Map<String, dynamic> json) {
    return Toc(
      id: json['id'],
      textId: json['text_id'],
      sections:
          (json['sections'] as List)
              .map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text_id': textId,
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }
}
