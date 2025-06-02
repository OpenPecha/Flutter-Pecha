import 'package:flutter_pecha/features/texts/models/term/term.dart';

class TermResponse {
  final Term? parent;
  final List<Term> terms;
  final int total;
  final int skip;
  final int limit;

  TermResponse({
    this.parent,
    required this.terms,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory TermResponse.fromJson(Map<String, dynamic> json) {
    return TermResponse(
      parent: json['parent'] != null ? Term.fromJson(json['parent']) : null,
      terms:
          (json['terms'] as List)
              .map((term) => Term.fromJson(term as Map<String, dynamic>))
              .toList(),
      total: json['total'] ?? 0,
      skip: json['skip'] ?? 0,
      limit: json['limit'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'parent': parent?.toJson(),
      'terms': terms.map((term) => term.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'TermResponse(parent: $parent, terms: $terms, total: $total, skip: $skip, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TermResponse &&
        other.parent == parent &&
        other.terms == terms &&
        other.total == total &&
        other.skip == skip &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return parent.hashCode ^
        terms.hashCode ^
        total.hashCode ^
        skip.hashCode ^
        limit.hashCode;
  }
}
