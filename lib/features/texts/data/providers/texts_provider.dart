import 'package:flutter_pecha/features/texts/data/datasource/text_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../repositories/texts_repository.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';

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
