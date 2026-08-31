import 'package:flutter_pecha/features/poems/domain/entities/poem.dart';

/// A page of published poems returned by `GET /poems`.
class PoemsPage {
  final List<Poem> poems;
  final int skip;
  final int limit;

  /// Whether another page is likely available.
  ///
  /// True total counts aren't guaranteed by the API contract, so this is
  /// heuristic: a full page (`poems.length == limit`) implies there may be
  /// more.
  final bool hasMore;

  const PoemsPage({
    required this.poems,
    this.skip = 0,
    this.limit = 20,
    this.hasMore = false,
  });
}
