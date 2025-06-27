import 'package:flutter_pecha/features/texts/models/segment.dart';

class Section {
  final String id;
  final String? title;
  final int sectionNumber;
  final String? parentId;
  final List<Segment> segments;
  final List<Section>? sections;
  final String? createdDate;
  final String? updatedDate;
  final String? publishedDate;

  const Section({
    required this.id,
    this.title,
    required this.sectionNumber,
    this.parentId,
    required this.segments,
    this.sections,
    this.createdDate,
    this.updatedDate,
    this.publishedDate,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String,
      title: json['title'] as String?,
      sectionNumber:
          json['section_number'] is int
              ? json['section_number'] as int
              : int.tryParse(json['section_number'].toString()) ?? 0,
      parentId: json['parent_id'] as String?,
      segments:
          (json['segments'] as List<dynamic>)
              .map((e) => Segment.fromJson(e as Map<String, dynamic>))
              .toList(),
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdDate: json['created_date'] as String?,
      updatedDate: json['updated_date'] as String?,
      publishedDate: json['published_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'section_number': sectionNumber,
      'parent_id': parentId,
      'segments': segments.map((e) => e.toJson()).toList(),
      'sections': sections?.map((e) => e.toJson()).toList(),
      'created_date': createdDate,
      'updated_date': updatedDate,
      'published_date': publishedDate,
    };
  }
}
