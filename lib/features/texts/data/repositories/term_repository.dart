// lib/features/texts/data/repositories/term_repository.dart
import 'package:flutter_pecha/features/texts/data/datasource/term_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/models/term/term_response.dart';

class TermRepository {
  final TermRemoteDatasource remoteDatasource;

  TermRepository({required this.remoteDatasource});

  Future<TermResponse> getTerms({
    String? parentId,
    String? language,
    int skip = 0,
    int limit = 10,
  }) {
    return remoteDatasource.fetchTerms(
      parentId: parentId,
      language: language,
      skip: skip,
      limit: limit,
    );
  }
}
