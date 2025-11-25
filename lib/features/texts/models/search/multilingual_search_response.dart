import 'package:flutter_pecha/features/texts/models/search/multilingual_source_result.dart';

class MultilingualSearchResponse {
  final String query;
  final String searchType;
  final List<MultilingualSourceResult> sources;
  final int skip;
  final int limit;
  final int total;

  MultilingualSearchResponse({
    required this.query,
    required this.searchType,
    required this.sources,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory MultilingualSearchResponse.fromJson(Map<String, dynamic> json) {
    try {
      return MultilingualSearchResponse(
        query: json['query'],
        searchType: json['search_type'],
        sources:
            (json['sources'] as List<dynamic>)
                .map(
                  (e) => MultilingualSourceResult.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
        skip: json['skip'],
        limit: json['limit'],
        total: json['total'],
      );
    } catch (e) {
      throw Exception(
        'MultilingualSearchResponse::: Failed to load multilingual search response',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'search_type': searchType,
      'sources': sources.map((e) => e.toJson()).toList(),
      'skip': skip,
      'limit': limit,
      'total': total,
    };
  }
}
