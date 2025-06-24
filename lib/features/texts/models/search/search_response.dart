import 'package:flutter_pecha/features/texts/models/search/search.dart';
import 'package:flutter_pecha/features/texts/models/search/source_result_item.dart';

class SearchResponse {
  final Search search;
  final List<SourceResultItem>? sources;

  SearchResponse({required this.search, required this.sources});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      search: Search.fromJson(json['search']),
      sources:
          (json['sources'] as List)
              .map((e) => SourceResultItem.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search': search.toJson(),
      'sources': sources?.map((e) => e.toJson()).toList(),
    };
  }
}
