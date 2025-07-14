import 'package:flutter_pecha/features/texts/data/datasource/share_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/repositories/share_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// HTTP client provider for dependency injection
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

// Share repository provider
final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return ShareRepository(
    remoteDatasource: ShareRemoteDatasource(client: client),
  );
});

// Share parameters model
class ShareUrlParams {
  final String textId;
  final String contentId;
  final String segmentId;
  final String language;

  const ShareUrlParams({
    required this.textId,
    required this.contentId,
    required this.segmentId,
    required this.language,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareUrlParams &&
          runtimeType == other.runtimeType &&
          textId == other.textId &&
          contentId == other.contentId &&
          segmentId == other.segmentId &&
          language == other.language;

  @override
  int get hashCode =>
      textId.hashCode ^
      contentId.hashCode ^
      segmentId.hashCode ^
      language.hashCode;
}

// Share URL provider
final shareUrlProvider = FutureProvider.family<String, ShareUrlParams>((
  ref,
  params,
) async {
  final repository = ref.watch(shareRepositoryProvider);
  try {
    final shortUrl = await repository.getShareUrl(
      textId: params.textId,
      contentId: params.contentId,
      segmentId: params.segmentId,
      language: params.language,
    );
    if (shortUrl.isEmpty) {
      throw Exception('Failed to generate share URL');
    }
    return shortUrl;
  } catch (e) {
    throw Exception('Failed to generate share URL: $e');
  }
});
