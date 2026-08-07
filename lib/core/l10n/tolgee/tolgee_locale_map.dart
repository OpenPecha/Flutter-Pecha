import 'dart:ui' show Locale;

/// Maps app UI locales (bare language codes) to Tolgee CDN language tags.
///
/// Content Delivery publishes:
/// `en`, `bo-IN`, `zh-Hant-TW`, `hi`, `mn`, `ne` under the `webuddhist`
/// namespace. The Flutter UI / ARB stack keeps using `bo` and `zh`.
class TolgeeLocaleMap {
  TolgeeLocaleMap._();

  /// CDN / Tolgee tag string for [appLocale] (used as `currentLanguage` and
  /// as `Locale.toString()` when the tag has no script subtag issues).
  static String cdnTagFor(Locale appLocale) {
    switch (appLocale.languageCode) {
      case 'bo':
        return 'bo-IN';
      case 'zh':
        return 'zh-Hant-TW';
      default:
        return appLocale.languageCode;
    }
  }

  /// Locale passed to `Tolgee.setCurrentLocale` so the SDK requests
  /// `{cdn}/{tag}.json` with hyphenated tags (`bo-IN`, `zh-Hant-TW`).
  ///
  /// Uses a single-argument [Locale] so `toString()` keeps hyphens; the usual
  /// `Locale('bo', 'IN')` form stringifies as `bo_IN`, which would 404.
  static Locale cdnLocaleFor(Locale appLocale) => Locale(cdnTagFor(appLocale));

  /// Canonical app language code for bridge matching (`bo`, `zh`, `en`, …).
  static String appLanguageCodeOf(String localeNameOrTag) {
    final String normalized = localeNameOrTag.replaceAll('_', '-');
    final String lower = normalized.toLowerCase();
    if (lower == 'bo-in' || lower == 'bo') {
      return 'bo';
    }
    if (lower.startsWith('zh')) {
      return 'zh';
    }
    final int separator = normalized.indexOf('-');
    return separator == -1
        ? normalized
        : normalized.substring(0, separator);
  }

  /// Whether Tolgee's loaded locale is compatible with the app locale name
  /// used by `AppLocalizations` (e.g. CDN `bo-IN` matches app `bo`).
  static bool matchesAppLocale(String appLocaleName, Locale? tolgeeLocale) {
    if (tolgeeLocale == null) {
      return false;
    }
    return appLanguageCodeOf(appLocaleName) ==
        appLanguageCodeOf(tolgeeLocale.toString());
  }
}
