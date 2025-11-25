import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';

class VersionResponse {
  final TextDetail? text;
  final List<Version>? versions;

  VersionResponse({this.text, this.versions});

  factory VersionResponse.fromJson(Map<String, dynamic> json) {
    return VersionResponse(
      text: json['text'] != null ? TextDetail.fromJson(json['text']) : null,
      versions:
          json['versions'] != null
              ? (json['versions'] as List)
                  .map((e) => Version.fromJson(e as Map<String, dynamic>))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text?.toJson(),
      'versions': versions?.map((e) => e.toJson()).toList(),
    };
  }
}
