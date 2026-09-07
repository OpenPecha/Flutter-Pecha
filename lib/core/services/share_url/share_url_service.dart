library;

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_remote_datasource.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShareUrlService {
  ShareUrlService({required ShareUrlRemoteDatasource remoteDatasource})
    : _remoteDatasource = remoteDatasource;

  final ShareUrlRemoteDatasource _remoteDatasource;
  final _logger = AppLogger('ShareUrlService');

  /// Returns a shortened URL, or [longUrl] when shortening fails.
  Future<String> shorten(String longUrl) async {
    final trimmed = longUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    try {
      return await _remoteDatasource.shortenUrl(trimmed);
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to shorten share URL, using original',
        e,
        stackTrace,
      );
      return trimmed;
    }
  }
}

final shareUrlRemoteDatasourceProvider = Provider<ShareUrlRemoteDatasource>((
  ref,
) {
  return ShareUrlRemoteDatasource(dio: ref.watch(dioProvider));
});

final shareUrlServiceProvider = Provider<ShareUrlService>((ref) {
  return ShareUrlService(
    remoteDatasource: ref.watch(shareUrlRemoteDatasourceProvider),
  );
});

/// Shortens [longUrl] for share flows that only have a [BuildContext].
Future<String> resolveShareUrl(BuildContext context, String longUrl) {
  return ProviderScope.containerOf(context, listen: false)
      .read(shareUrlServiceProvider)
      .shorten(longUrl);
}

/// Shortens [longUrl] for share flows that have a [WidgetRef].
Future<String> resolveShareUrlRef(WidgetRef ref, String longUrl) {
  return ref.read(shareUrlServiceProvider).shorten(longUrl);
}
