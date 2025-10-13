import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';

class TextDetailResponse {
  final Collections collections;
  final List<Texts> texts;
  final int total;
  final int skip;
  final int limit;

  TextDetailResponse({
    required this.collections,
    required this.texts,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory TextDetailResponse.fromJson(Map<String, dynamic> json) {
    return TextDetailResponse(
      collections: Collections.fromJson(json['collection']),
      texts: (json['texts'] as List).map((e) => Texts.fromJson(e)).toList(),
      total: json['total'],
      skip: json['skip'],
      limit: json['limit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collection': collections.toJson(),
      'texts': texts.map((e) => e.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
  }
}
