import 'package:flutter_pecha/features/texts/models/collections/collections.dart';

class Pagination {
  final int total;
  final int skip;
  final int limit;

  Pagination({required this.total, required this.skip, required this.limit});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'skip': skip, 'limit': limit};
  }

  @override
  String toString() {
    return 'Pagination(total: $total, skip: $skip, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pagination &&
        other.total == total &&
        other.skip == skip &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return total.hashCode ^ skip.hashCode ^ limit.hashCode;
  }
}

class CollectionsResponse {
  final Collections? parent;
  final List<Collections> collections;
  final Pagination pagination;

  CollectionsResponse({
    this.parent,
    required this.collections,
    required this.pagination,
  });

  factory CollectionsResponse.fromJson(Map<String, dynamic> json) {
    return CollectionsResponse(
      parent:
          json['parent'] != null ? Collections.fromJson(json['parent']) : null,
      collections:
          (json['collections'] as List)
              .map(
                (collection) =>
                    Collections.fromJson(collection as Map<String, dynamic>),
              )
              .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'parent': parent?.toJson(),
      'collections':
          collections.map((collection) => collection.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  @override
  String toString() {
    return 'CollectionsResponse(parent: $parent, collections: $collections, pagination: $pagination)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CollectionsResponse &&
        other.parent == parent &&
        other.collections == collections &&
        other.pagination == pagination;
  }

  @override
  int get hashCode {
    return parent.hashCode ^ collections.hashCode ^ pagination.hashCode;
  }
}
