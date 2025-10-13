import 'package:flutter_pecha/features/texts/models/collections/collections.dart';

class CollectionsResponse {
  final Collections? parent;
  final List<Collections> collections;
  final int total;
  final int skip;
  final int limit;

  CollectionsResponse({
    this.parent,
    required this.collections,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory CollectionsResponse.fromJson(Map<String, dynamic> json) {
    return CollectionsResponse(
      parent:
          json['parent'] != null ? Collections.fromJson(json['parent']) : null,
      collections:
          (json['collections'] as List)
              .map((collection) => Collections.fromJson(collection as Map<String, dynamic>))
              .toList(),
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'parent': parent?.toJson(),
      'collections':
          collections.map((collection) => collection.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'CollectionsResponse(parent: $parent, collections: $collections, total: $total, skip: $skip, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CollectionsResponse &&
        other.parent == parent &&
        other.collections == collections &&
        other.total == total &&
        other.skip == skip &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return parent.hashCode ^
        collections.hashCode ^
        total.hashCode ^
        skip.hashCode ^
        limit.hashCode;
  }
}
