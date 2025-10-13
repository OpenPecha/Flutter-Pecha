// lib/features/texts/data/repositories/term_repository.dart
import 'package:flutter_pecha/features/texts/data/datasource/collections_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections_response.dart';

class CollectionsRepository {
  final CollectionsRemoteDatasource remoteDatasource;

  CollectionsRepository({required this.remoteDatasource});

  Future<CollectionsResponse> getCollections({
    String? parentId,
    String? language,
    int skip = 0,
    int limit = 10,
  }) {
    return remoteDatasource.fetchCollections(
      parentId: parentId,
      language: language,
      skip: skip,
      limit: limit,
    );
  }
}
