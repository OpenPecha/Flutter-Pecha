import 'package:flutter_pecha/features/texts/data/datasource/share_remote_datasource.dart';

class ShareRepository {
  final ShareRemoteDatasource remoteDatasource;

  ShareRepository({required this.remoteDatasource});

  Future<String> getShareUrl({
    required String textId,
    required String contentId,
    required String segmentId,
    required String language,
  }) async {
    if (textId.isEmpty ||
        contentId.isEmpty ||
        segmentId.isEmpty ||
        language.isEmpty) {
      throw ArgumentError('All parameters must be non-empty');
    }

    try {
      final shortUrl = await remoteDatasource.getShareUrl(
        textId: textId,
        contentId: contentId,
        segmentId: segmentId,
        language: language,
      );

      if (shortUrl.isEmpty) {
        throw Exception('Server returned empty share URL');
      }

      return shortUrl;
    } catch (e) {
      throw Exception('Failed to generate share URL: $e');
    }
  }
}
