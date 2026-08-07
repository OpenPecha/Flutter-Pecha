import 'package:intl/message_format.dart';
import 'package:tolgee/tolgee.dart';

import 'tolgee_locale_map.dart';

/// Runtime lookup layer sitting between the generated `AppLocalizations`
/// overrides and the Tolgee SDK.
///
/// Every lookup falls back to the bundled ARB translation, so the app behaves
/// exactly as it did before Tolgee whenever the SDK is disabled, still loading,
/// offline, or missing the key.
class TolgeeBridge {
  TolgeeBridge._();

  /// Set to true only after [Tolgee.init] succeeds. While false the bridge is
  /// completely inert and every lookup resolves to the bundled ARB value.
  static bool active = false;

  /// Cached raw Tolgee strings for the current revision. A stored `null` means
  /// "known miss" and is preserved so repeated lookups stay O(1) — the SDK
  /// itself does a linear scan over every key on each `translate` call.
  static final Map<String, String?> _cache = <String, String?>{};

  /// Drops the memoized lookups. Called whenever Tolgee reports new data or the
  /// language changes.
  static void invalidate() => _cache.clear();

  /// Resets all bridge state. Used by tests.
  static void reset() {
    active = false;
    _cache.clear();
  }

  /// Resolves a translation with no placeholders.
  static String get(String localeName, String key, String Function() fallback) {
    return _raw(localeName, key) ?? fallback();
  }

  /// Resolves a translation containing ICU placeholders or plurals.
  ///
  /// Falls back to the bundled ARB value when the remote string cannot be
  /// formatted, which guards against a malformed ICU message published in
  /// Tolgee taking down a screen.
  static String format(
    String localeName,
    String key,
    Map<String, Object> args,
    String Function() fallback,
  ) {
    final String? raw = _raw(localeName, key);
    if (raw == null || !raw.contains('{')) {
      return fallback();
    }
    try {
      return MessageFormat(raw, locale: localeName).format(args);
    } catch (_) {
      return fallback();
    }
  }

  static String? _raw(String localeName, String key) {
    if (!active) {
      return null;
    }
    if (!_matchesCurrentLanguage(localeName)) {
      return null;
    }
    return _cache.putIfAbsent(key, () {
      // The SDK returns the key itself (ignoring defaultValue) when it has no
      // current language, and returns defaultValue when the key is missing.
      // Passing the key as the default collapses both cases into one check.
      final String value = Tolgee.translate(key: key, defaultValue: key);
      if (value == key || value.isEmpty) {
        return null;
      }
      return value;
    });
  }

  /// Guards against serving strings for the wrong language.
  ///
  /// Tolgee holds exactly one language in memory at a time and swaps it
  /// asynchronously. Until its fetch for the new language lands, the requested
  /// locale and the loaded one disagree, and serving the loaded one would mix
  /// languages in the UI.
  ///
  /// CDN tags like `bo-IN` / `zh-Hant-TW` are treated as matching app locales
  /// `bo` / `zh` via [TolgeeLocaleMap].
  static bool _matchesCurrentLanguage(String localeName) {
    try {
      return TolgeeLocaleMap.matchesAppLocale(
        localeName,
        Tolgee.currentLocale,
      );
    } catch (_) {
      // `Tolgee.currentLocale` throws when the SDK is not initialized.
      return false;
    }
  }
}
