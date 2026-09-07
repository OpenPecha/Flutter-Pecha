library;

import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class AppShareService {
  AppShareService({required ShareUrlService shareUrlService})
    : _shareUrlService = shareUrlService;

  final ShareUrlService _shareUrlService;
  final _logger = AppLogger('AppShareService');

  Future<String> buildShareMessage(String localizedMessage) async {
    final link = await _shareUrlService.shorten(AppConfig.airbridgeTrackingLink);
    return '$localizedMessage\n\n$link';
  }

  Future<void> shareApp(String localizedMessage) async {
    try {
      _logger.info('Sharing WeBuddhist app with Airbridge tracking link');

      await SharePlus.instance.share(
        ShareParams(
          text: await buildShareMessage(localizedMessage),
        ),
      );

      _logger.info('App share completed successfully');
    } catch (e) {
      _logger.error('Error sharing app', e);
      rethrow;
    }
  }
}

final appShareServiceProvider = Provider<AppShareService>((ref) {
  return AppShareService(shareUrlService: ref.watch(shareUrlServiceProvider));
});
