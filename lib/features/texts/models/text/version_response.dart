import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';

class VersionResponse {
  final TextDetail text;
  final List<Version> versions;

  VersionResponse({required this.text, required this.versions});

  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      text: TextDetail.fromJson(json['text']),
      versions:
          (json['versions'] as List)
              .map((e) => Version.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text.toJson(),
      'versions': versions.map((e) => e.toJson()).toList(),
    };
  }
}
