import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/texts_repository.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';

class TextDetailsParams {
  final String textId;
  final String? contentId;
  final String? versionId;
  final String? skip;
  const TextDetailsParams({
    required this.textId,
    this.contentId,
    this.versionId,
    this.skip,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextDetailsParams &&
          runtimeType == other.runtimeType &&
          textId == other.textId &&
          contentId == other.contentId &&
          versionId == other.versionId &&
          skip == other.skip;

  @override
  int get hashCode =>
      textId.hashCode ^
      (contentId?.hashCode ?? 0) ^
      (versionId?.hashCode ?? 0) ^
      (skip?.hashCode ?? 0);
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
      .fetchTextDetails(
        textId: params.textId,
        contentId: params.contentId!,
        versionId: params.versionId,
        skip: params.skip,
      );
});
