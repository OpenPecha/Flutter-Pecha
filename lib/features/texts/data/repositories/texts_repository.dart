import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/models/search/search_response.dart';
import 'package:flutter_pecha/features/texts/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/models/text/version_response.dart';

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

  Future<TocResponse> fetchTextContent({required String textId}) async {
    return remoteDatasource.fetchTextContent(textId: textId);
  }

  Future<VersionResponse> fetchTextVersion({required String textId}) async {
    return remoteDatasource.fetchTextVersion(textId: textId);
  }

  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    required String contentId,
    String? versionId,
    String? segmentId,
    String? sectionId,
    String? direction,
  }) async {
    final result = await remoteDatasource.fetchTextDetails(
      textId: textId,
      contentId: contentId,
      versionId: versionId,
      segmentId: segmentId,
      sectionId: sectionId,
      direction: direction,
    );
    return result;
  }

  Future<SearchResponse> searchTextRepository({
    required String query,
    required String textId,
  }) async {
    final result = await remoteDatasource.searchText(
      query: query,
      textId: textId,
    );
    return result;
  }
}
