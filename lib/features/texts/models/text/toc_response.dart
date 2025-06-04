import 'package:flutter_pecha/features/texts/models/text/toc.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';

class TocResponse {
  final TextDetail textDetail;
  final List<Toc> contents;

  TocResponse({required this.textDetail, required this.contents});

  factory TocResponse.fromJson(Map<String, dynamic> json) {
    return TocResponse(
      textDetail: TextDetail.fromJson(json['text_detail']),
      contents: (json['contents'] as List).map((e) => Toc.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text_detail': textDetail.toJson(),
      'contents': contents.map((e) => e.toJson()).toList(),
    };
  }
}
