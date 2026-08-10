import 'dart:ui' show Locale;

import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_bridge.dart';
import 'package:flutter_pecha/core/l10n/tolgee/tolgee_localizations_delegate.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Tolgee SDK is never initialized in these tests, which is exactly the
/// state a release build is in when Tolgee is disabled, offline, or still
/// fetching. Everything must fall through to the bundled ARB translations.
void main() {
  setUp(TolgeeBridge.reset);
  tearDown(TolgeeBridge.reset);

  const List<Locale> locales = <Locale>[
    Locale('en'),
    Locale('bo'),
    Locale('zh'),
    Locale('hi'),
    Locale('mn'),
    Locale('ne'),
  ];

  group('bridge inactive', () {
    test('plain keys match the bundled ARB value in every locale', () {
      for (final Locale locale in locales) {
        final AppLocalizations bundled = lookupAppLocalizations(locale);
        final AppLocalizations bridged = tolgeeAppLocalizationsFor(locale);

        expect(bridged.sign_in, bundled.sign_in, reason: '$locale sign_in');
        expect(bridged.logout, bundled.logout, reason: '$locale logout');
        expect(
          bridged.creator_featured_plan,
          bundled.creator_featured_plan,
          reason: '$locale creator_featured_plan',
        );
      }
    });

    test('parameterized and plural keys match the bundled ARB value', () {
      for (final Locale locale in locales) {
        final AppLocalizations bundled = lookupAppLocalizations(locale);
        final AppLocalizations bridged = tolgeeAppLocalizationsFor(locale);

        expect(bridged.ai_greeting('Tenzin'), bundled.ai_greeting('Tenzin'));
        expect(bridged.plan_day_of(2, 9), bundled.plan_day_of(2, 9));
        for (final int count in <int>[0, 1, 7]) {
          expect(
            bridged.mala_rounds_count(count),
            bundled.mala_rounds_count(count),
            reason: '$locale mala_rounds_count($count)',
          );
        }
      }
    });

    test(
      'localeName is preserved so downstream Intl formatting is correct',
      () {
        for (final Locale locale in locales) {
          expect(
            tolgeeAppLocalizationsFor(locale).localeName,
            lookupAppLocalizations(locale).localeName,
          );
        }
      },
    );

    test('lookups return the fallback without touching the SDK', () {
      expect(TolgeeBridge.get('en', 'sign_in', () => 'Sign in'), 'Sign in');
      expect(
        TolgeeBridge.format('en', 'ai_greeting', <String, Object>{
          'name': 'Tenzin',
        }, () => 'Hi Tenzin'),
        'Hi Tenzin',
      );
    });
  });

  group('bridge active but SDK unavailable', () {
    // `Tolgee.currentLocale` throws when the SDK was never initialized. The
    // bridge has to swallow that rather than propagate it into a widget build.
    setUp(() => TolgeeBridge.active = true);

    test('falls back instead of throwing', () {
      expect(TolgeeBridge.get('en', 'sign_in', () => 'Sign in'), 'Sign in');
      expect(
        TolgeeBridge.format('en', 'home_plans_count', <String, Object>{
          'count': 3,
        }, () => '3 plans'),
        '3 plans',
      );
    });

    test('generated overrides still resolve to bundled ARB values', () {
      final AppLocalizations bundled = lookupAppLocalizations(
        const Locale('bo'),
      );
      final AppLocalizations bridged = tolgeeAppLocalizationsFor(
        const Locale('bo'),
      );
      expect(bridged.sign_in, bundled.sign_in);
      expect(bridged.mala_rounds_count(3), bundled.mala_rounds_count(3));
    });
  });
}
