import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';

class ReaderResponse {
  final TextDetail textDetail;
  final Toc content;

  ReaderResponse({required this.textDetail, required this.content});

  factory ReaderResponse.fromJson(Map<String, dynamic> json) {
    return ReaderResponse(
      textDetail: TextDetail.fromJson(json['text_detail']),
      content: Toc.fromJson(json['content']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text_detail': textDetail.toJson(), 'content': content.toJson()};
  }
}
