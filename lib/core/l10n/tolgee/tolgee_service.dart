import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tolgee/tolgee.dart';

import '../../../env.dart';
import '../../utils/app_logger.dart';
import 'tolgee_bridge.dart';
import 'tolgee_locale_map.dart';

/// Incremented whenever Tolgee has new translations in memory.
///
/// `_MyAppState` watches this and feeds it to [TolgeeAppLocalizationsDelegate],
/// which is what makes `Localizations` re-resolve every string.
final StateProvider<int> tolgeeRevisionProvider = StateProvider<int>(
  (ref) => 0,
);

/// Owns the Tolgee SDK lifecycle.
///
/// Every entry point is failure-tolerant: if anything goes wrong the bridge
/// stays inactive and the app keeps using its bundled ARB translations.
class TolgeeService {
  TolgeeService._();

  static final AppLogger _logger = AppLogger('Tolgee');

  /// The SDK issues plain `package:http` calls with no timeout of their own,
  /// so an unreachable host would otherwise leave the future pending forever.
  static const Duration _networkTimeout = Duration(seconds: 15);

  /// Stable keys used to prove the CDN payload actually loaded.
  ///
  /// The SDK does not throw on 404/empty CDN responses, so we probe after
  /// `setCurrentLocale` before flipping [TolgeeBridge.active].
  static const List<String> _readinessProbeKeys = <String>[
    'appTitle',
    'sign_in',
  ];

  /// Fetches translations for [locale] and activates the bridge.
  ///
  /// Returns whether over-the-air translations are now live. Safe to call when
  /// Tolgee is unconfigured, in which case it is a no-op.
  static Future<bool> initialize({required Locale locale}) async {
    if (!Env.tolgeeEnabled) {
      _logger.info('Tolgee disabled for this build; using bundled ARB');
      return false;
    }

    final String? apiKey = Env.tolgeeApiKey;
    final String? cdnUrl = Env.tolgeeCdnUrl;
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'Flutter' ||
        cdnUrl == null ||
        cdnUrl.isEmpty) {
      _logger.warning(
        'Tolgee enabled but TOLGEE_API_KEY or TOLGEE_CDN_URL is missing; '
        'using bundled ARB',
      );
      return false;
    }

    final Locale cdnLocale = TolgeeLocaleMap.cdnLocaleFor(locale);
    final String cdnTag = TolgeeLocaleMap.cdnTagFor(locale);

    try {
      await Tolgee.init(
        apiKey: apiKey,
        apiUrl: Env.tolgeeApiUrl,
        cdnUrl: cdnUrl,
        useCDN: true,
        currentLanguage: cdnTag,
      ).timeout(_networkTimeout);

      // `Tolgee.init` starts its first translation fetch without awaiting it,
      // and may normalize multi-part tags incorrectly — this awaited call is
      // what loads `{cdn}/{tag}.json` into memory.
      await Tolgee.setCurrentLocale(cdnLocale).timeout(_networkTimeout);

      if (!_hasLoadedTranslations()) {
        TolgeeBridge.active = false;
        TolgeeBridge.invalidate();
        _logger.warning(
          'Tolgee CDN returned no usable strings for $cdnTag '
          '(probed ${_readinessProbeKeys.join(", ")}); using bundled ARB',
        );
        return false;
      }

      TolgeeBridge.invalidate();
      TolgeeBridge.active = true;
      _logger.info(
        'Tolgee ready for ${locale.languageCode} (CDN tag $cdnTag)',
      );
      return true;
    } catch (error) {
      TolgeeBridge.active = false;
      _logger.warning('Tolgee init failed ($error); using bundled ARB');
      return false;
    }
  }

  /// Loads translations for a newly selected [locale].
  ///
  /// Returns whether the caller should refresh the UI.
  static Future<bool> setLocale(Locale locale) async {
    if (!TolgeeBridge.active) {
      return false;
    }
    final Locale cdnLocale = TolgeeLocaleMap.cdnLocaleFor(locale);
    final String cdnTag = TolgeeLocaleMap.cdnTagFor(locale);
    // Drop memoized strings up front: the bridge refuses to serve values whose
    // language does not match the request, so during the fetch it falls back
    // to the bundled ARB rather than showing the previous language.
    TolgeeBridge.invalidate();
    try {
      await Tolgee.setCurrentLocale(cdnLocale).timeout(_networkTimeout);
      if (!_hasLoadedTranslations()) {
        _logger.warning(
          'Tolgee language switch to $cdnTag loaded no usable strings',
        );
        return false;
      }
      TolgeeBridge.invalidate();
      _logger.info(
        'Tolgee switched to ${locale.languageCode} (CDN tag $cdnTag)',
      );
      return true;
    } catch (error) {
      _logger.warning('Tolgee language switch failed ($error)');
      return false;
    }
  }

  static bool _hasLoadedTranslations() {
    for (final String key in _readinessProbeKeys) {
      final String value = Tolgee.translate(key: key, defaultValue: key);
      if (value != key && value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
