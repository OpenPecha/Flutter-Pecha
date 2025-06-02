import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';

class TextsRepository {
  final TextRemoteDatasource remoteDatasource;

  TextsRepository({required this.remoteDatasource});

  Future<TextDetailResponse> getTexts({
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

  Future<List<Section>> fetchTextContent({required String textId}) async {
    return remoteDatasource.fetchTextContent(textId: textId);
  }

  Future<List<Version>> fetchTextVersion({required String textId}) async {
    return remoteDatasource.fetchTextVersion(textId: textId);
  }

  Future<Map<String, dynamic>> fetchTextDetails({
    required String textId,
    required String contentId,
    String? versionId,
    String? skip,
  }) async {
    return remoteDatasource.fetchTextDetails(
      textId: textId,
      contentId: contentId,
      versionId: versionId,
      skip: skip,
    );
  }
}
