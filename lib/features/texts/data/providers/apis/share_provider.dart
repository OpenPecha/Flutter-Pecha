import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/texts/data/datasource/share_remote_datasource.dart';
import 'package:flutter_pecha/features/texts/data/repositories/share_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Share repository provider
final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ShareRepository(
    remoteDatasource: ShareRemoteDatasource(client: client),
  );
});

// Share parameters model
class ShareUrlParams {
  final String textId;
  final String segmentId;
  final String language;

  const ShareUrlParams({
    required this.textId,
    required this.segmentId,
    required this.language,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareUrlParams &&
          runtimeType == other.runtimeType &&
          textId == other.textId &&
          segmentId == other.segmentId &&
          language == other.language;

  @override
  int get hashCode => textId.hashCode ^ segmentId.hashCode ^ language.hashCode;
}

// Share URL provider
final shareUrlProvider = FutureProvider.autoDispose
    .family<String, ShareUrlParams>((ref, params) async {
      final repository = ref.watch(shareRepositoryProvider);
      try {
        final shortUrl = await repository.getShareUrl(
          textId: params.textId,
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
