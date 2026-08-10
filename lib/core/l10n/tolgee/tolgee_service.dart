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

  /// Newest locale the UI has asked for. `localeProvider` restores the stored
  /// language asynchronously, so a change can land while the fetch for the
  /// default locale is still in flight; whichever run finishes last has to
  /// converge on this value rather than on the locale it started with.
  static Locale? _desiredLocale;

  /// App locale whose payload [_hasLoadedTranslations] last proved loaded.
  static Locale? _loadedLocale;

  /// `Tolgee.init` may only run once per process.
  static bool _sdkInitialized = false;

  /// Serialises SDK work. Tolgee holds exactly one language in memory, so
  /// overlapping `setCurrentLocale` calls would race over shared state.
  static Future<void> _chain = Future<void>.value();

  /// Keeps a misconfigured build from repeating the same warning on every
  /// language change.
  static bool _configIssueLogged = false;

  /// Fetches translations for [locale] and activates the bridge.
  ///
  /// Returns whether over-the-air translations are now live. Safe to call when
  /// Tolgee is unconfigured, in which case it is a no-op.
  static Future<bool> initialize({required Locale locale}) => _sync(locale);

  /// Loads translations for a newly selected [locale].
  ///
  /// Returns whether the caller should refresh the UI. Safe to call before
  /// [initialize] has finished: the request is recorded and the in-flight run
  /// picks it up instead of being dropped.
  static Future<bool> setLocale(Locale locale) => _sync(locale);

  static Future<bool> _sync(Locale locale) {
    _desiredLocale = locale;
    if (!_isConfigured()) {
      return Future<bool>.value(false);
    }
    final Future<bool> run = _chain.then((_) => _load());
    // Swallow so a failed run cannot poison the queue for later language
    // changes, but surface it: callers reach this via `unawaited`, so nothing
    // else would ever report an error that escaped `_load`.
    _chain = run.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _logger.warning('Tolgee load run failed', error, stackTrace);
      },
    );
    return run;
  }

  static bool _isConfigured() {
    if (!Env.tolgeeEnabled) {
      if (!_configIssueLogged) {
        _configIssueLogged = true;
        _logger.info('Tolgee disabled for this build; using bundled ARB');
      }
      return false;
    }
    final String? apiKey = Env.tolgeeApiKey;
    final String? cdnUrl = Env.tolgeeCdnUrl;
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'Flutter' ||
        cdnUrl == null ||
        cdnUrl.isEmpty) {
      if (!_configIssueLogged) {
        _configIssueLogged = true;
        _logger.warning(
          'Tolgee enabled but TOLGEE_API_KEY or TOLGEE_CDN_URL is missing; '
          'using bundled ARB',
        );
      }
      return false;
    }
    return true;
  }

  /// Brings the SDK onto [_desiredLocale], re-reading it after every await so a
  /// language change that arrives mid-fetch wins instead of being discarded.
  static Future<bool> _load() async {
    while (true) {
      final Locale target = _desiredLocale!;
      if (_loadedLocale == target && TolgeeBridge.active) {
        return true;
      }

      final Locale cdnLocale = TolgeeLocaleMap.cdnLocaleFor(target);
      final String cdnTag = TolgeeLocaleMap.cdnTagFor(target);
      final bool isFirstLoad = _loadedLocale == null;
      // Drop memoized strings up front: the bridge refuses to serve values
      // whose language does not match the request, so during the fetch it falls
      // back to the bundled ARB rather than showing the previous language.
      TolgeeBridge.invalidate();

      try {
        if (!_sdkInitialized) {
          await Tolgee.init(
            apiKey: Env.tolgeeApiKey!,
            apiUrl: Env.tolgeeApiUrl,
            cdnUrl: Env.tolgeeCdnUrl!,
            useCDN: true,
            currentLanguage: cdnTag,
          ).timeout(_networkTimeout);
          _sdkInitialized = true;
        }

        // `Tolgee.init` starts its first translation fetch without awaiting it,
        // and may normalize multi-part tags incorrectly — this awaited call is
        // what loads `{cdn}/{tag}.json` into memory.
        await Tolgee.setCurrentLocale(cdnLocale).timeout(_networkTimeout);

        // The UI moved on while we were fetching; activating now would pin the
        // bridge to a language nothing is asking for.
        if (_desiredLocale != target) {
          continue;
        }

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
        _loadedLocale = target;
        _logger.info(
          isFirstLoad
              ? 'Tolgee ready for ${target.languageCode} (CDN tag $cdnTag)'
              : 'Tolgee switched to ${target.languageCode} (CDN tag $cdnTag)',
        );
        return true;
      } catch (error, stackTrace) {
        TolgeeBridge.active = false;
        _logger.warning(
          isFirstLoad
              ? 'Tolgee init failed; using bundled ARB'
              : 'Tolgee language switch failed',
          error,
          stackTrace,
        );
        return false;
      }
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
