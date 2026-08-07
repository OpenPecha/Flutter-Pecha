import 'dart:ui' show Locale;

import 'package:flutter_pecha/core/l10n/tolgee/tolgee_locale_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TolgeeLocaleMap.cdnTagFor', () {
    test('maps bo and zh to published CDN tags', () {
      expect(TolgeeLocaleMap.cdnTagFor(const Locale('bo')), 'bo-IN');
      expect(TolgeeLocaleMap.cdnTagFor(const Locale('zh')), 'zh-Hant-TW');
    });

    test('passes through en hi mn ne', () {
      for (final String code in <String>['en', 'hi', 'mn', 'ne']) {
        expect(TolgeeLocaleMap.cdnTagFor(Locale(code)), code);
      }
    });
  });

  group('TolgeeLocaleMap.cdnLocaleFor', () {
    test('toString keeps hyphenated CDN tags for the SDK URL', () {
      expect(
        TolgeeLocaleMap.cdnLocaleFor(const Locale('bo')).toString(),
        'bo-IN',
      );
      expect(
        TolgeeLocaleMap.cdnLocaleFor(const Locale('zh')).toString(),
        'zh-Hant-TW',
      );
      expect(
        TolgeeLocaleMap.cdnLocaleFor(const Locale('en')).toString(),
        'en',
      );
    });
  });

  group('TolgeeLocaleMap.matchesAppLocale', () {
    test('CDN bo-IN matches app bo', () {
      expect(
        TolgeeLocaleMap.matchesAppLocale('bo', const Locale('bo-IN')),
        isTrue,
      );
      expect(
        TolgeeLocaleMap.matchesAppLocale('bo', const Locale('en')),
        isFalse,
      );
    });

    test('CDN zh-Hant-TW matches app zh', () {
      expect(
        TolgeeLocaleMap.matchesAppLocale(
          'zh',
          const Locale('zh-Hant-TW'),
        ),
        isTrue,
      );
    });
  });
}
