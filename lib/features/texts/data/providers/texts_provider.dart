import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/texts_repository.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';

class TextDetailsParams {
  final String textId;
  final String contentId;
  final String? versionId;
  final String? segmentId;
  final String? sectionId;
  final String? direction;
  final String key;
  const TextDetailsParams({
    required this.textId,
    required this.contentId,
    this.versionId,
    this.segmentId,
    this.sectionId,
    this.direction,
  }) : key = '${textId}_${contentId}_${versionId}_${segmentId}_${sectionId}_$direction';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextDetailsParams &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

final textsRepositoryProvider = Provider<TextsRepository>(
  (ref) => TextsRepository(
    remoteDatasource: TextRemoteDatasource(client: http.Client()),
  ),
);

final textsFutureProvider = FutureProvider.family((ref, String termId) {
  final locale = ref.watch(localeProvider);
  final languageCode = locale?.languageCode;
  return ref
      .watch(textsRepositoryProvider)
      .getTexts(termId: termId, language: languageCode);
});

final textContentFutureProvider = FutureProvider.family((ref, String textId) {
  return ref.watch(textsRepositoryProvider).fetchTextContent(textId: textId);
});

final textVersionFutureProvider = FutureProvider.family((ref, String textId) {
  return ref.watch(textsRepositoryProvider).fetchTextVersion(textId: textId);
});

final textDetailsFutureProvider = FutureProvider.family((
  ref,
  TextDetailsParams params,
) {
  return ref
      .watch(textsRepositoryProvider)
      // .fetchTextDetails(
        // textId: params.textId,
        // contentId: params.contentId!,
        // versionId: params.versionId,
        // skip: params.skip,
      // );

      // update pagination
      .fetchTextDetails(
        textId: params.textId,
        contentId: params.contentId,
        versionId: params.versionId,
        segmentId: params.segmentId,
        sectionId: params.sectionId,
        direction: params.direction,
      );
});

class SearchTextParams {
  final String query;
  final String textId;
  const SearchTextParams({required this.query, required this.textId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchTextParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          textId == other.textId;

  @override
  int get hashCode => query.hashCode ^ textId.hashCode;
}

final searchTextFutureProvider = FutureProvider.family((
  ref,
  SearchTextParams params,
) {
  final result = ref
      .watch(textsRepositoryProvider)
      .searchTextRepository(query: params.query, textId: params.textId);
  return result;
});
