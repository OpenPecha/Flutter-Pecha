import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/models/search/multilingual_search_response.dart';
import 'package:flutter_pecha/features/texts/models/search/search_response.dart';
import 'package:flutter_pecha/features/texts/models/text/commentary_text_response.dart';
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
    int limit = 20,
  }) {
    return remoteDatasource.fetchTexts(
      termId: termId,
      language: language,
      skip: skip,
      limit: limit,
    );
  }

  Future<TocResponse> fetchTextContent({
    required String textId,
    String? language,
  }) async {
    return remoteDatasource.fetchTextContent(
      textId: textId,
      language: language,
    );
  }

  Future<VersionResponse> fetchTextVersion({
    required String textId,
    String? language,
  }) async {
    return remoteDatasource.fetchTextVersion(
      textId: textId,
      language: language,
    );
  }

  Future<CommentaryTextResponse> fetchCommentaryText({
    required String textId,
    String? language,
  }) async {
    return remoteDatasource.fetchCommentaryText(
      textId: textId,
      language: language,
    );
  }

  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    String? contentId,
    String? versionId,
    String? segmentId,
    String? direction,
  }) async {
    final result = await remoteDatasource.fetchTextDetails(
      textId: textId,
      contentId: contentId,
      versionId: versionId,
      segmentId: segmentId,
      direction: direction,
    );
    return result;
  }

  Future<SearchResponse> searchTextRepository({
    required String query,
    String? textId,
  }) async {
    final result = await remoteDatasource.searchText(
      query: query,
      textId: textId,
    );
    return result;
  }

  Future<MultilingualSearchResponse> multilingualSearchRepository({
    required String query,
    String? language,
    String? textId,
  }) async {
    final result = await remoteDatasource.multilingualSearch(
      query: query,
      language: language,
      textId: textId,
    );
    return result;
  }
}
