import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/models/texts.dart';

class TextsRepository {
  final TextRemoteDatasource remoteDatasource;

  TextsRepository({required this.remoteDatasource});

  Future<List<Texts>> getTexts({
    required String termId,
    String? language,
    int skip = 0,
    int limit = 10,
  }) {
    return remoteDatasource.fetchTexts(
      termId: termId,
      language: language,
      skip: skip,
      limit: limit,
    );
  }
}
