import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';
import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'locale_provider_test.mocks.dart';

// Generate mock using build_runner:
// flutter pub run build_runner build
@GenerateMocks([PreferencesService])
void main() {
  late MockPreferencesService mockPrefsService;
  late LocaleNotifier localeNotifier;

  setUp(() {
    mockPrefsService = MockPreferencesService();
  });

  tearDown(() {
    // Clean up after each test
    localeNotifier.dispose();
  });

  group('LocaleNotifier - Valid Scenarios', () {
    test('should load valid stored locale "en" on initialization', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'en');

      // Act
      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero); // Wait for async initialization

      // Assert
      expect(localeNotifier.state?.languageCode, 'en');
      verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
    });

    test('should load valid stored locale "bo" on initialization', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'bo');

      // Act
      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Assert
      expect(localeNotifier.state?.languageCode, 'bo');
      verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
    });

    test('should load valid stored locale "zh" on initialization', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'zh');

      // Act
      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Assert
      expect(localeNotifier.state?.languageCode, 'zh');
      verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
    });

    test('should set and persist new locale', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => null);
      when(
        mockPrefsService.set<String>(StorageKeys.locale, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Act
      await localeNotifier.setLocale(const Locale('bo'));

      // Assert
      expect(localeNotifier.state?.languageCode, 'bo');
      verify(mockPrefsService.set<String>(StorageKeys.locale, 'bo')).called(1);
    });

    test(
      'should default to "en" on first launch with no stored data',
      () async {
        // Arrange
        when(
          mockPrefsService.get<String>(StorageKeys.locale),
        ).thenAnswer((_) async => null);

        // Act
        localeNotifier = LocaleNotifier(mockPrefsService);
        await Future.delayed(Duration.zero);

        // Assert
        expect(localeNotifier.state?.languageCode, 'en');
        verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
      },
    );

    test('should persist locale change correctly', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'en');
      when(
        mockPrefsService.set<String>(StorageKeys.locale, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Act
      await localeNotifier.setLocale(const Locale('zh'));
      await localeNotifier.setLocale(const Locale('bo'));

      // Assert
      expect(localeNotifier.state?.languageCode, 'bo');
      verify(mockPrefsService.set<String>(StorageKeys.locale, 'zh')).called(1);
      verify(mockPrefsService.set<String>(StorageKeys.locale, 'bo')).called(1);
    });
  });

  group('LocaleNotifier - Invalid Scenarios', () {
    test(
      'should fall back to "en" when stored locale is unsupported (fr)',
      () async {
        // Arrange
        when(
          mockPrefsService.get<String>(StorageKeys.locale),
        ).thenAnswer((_) async => 'fr');

        // Act
        localeNotifier = LocaleNotifier(mockPrefsService);
        await Future.delayed(Duration.zero);

        // Assert
        expect(localeNotifier.state?.languageCode, 'en');
        verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
      },
    );

    test(
      'should fall back to "en" when stored locale is unsupported (de)',
      () async {
        // Arrange
        when(
          mockPrefsService.get<String>(StorageKeys.locale),
        ).thenAnswer((_) async => 'de');

        // Act
        localeNotifier = LocaleNotifier(mockPrefsService);
        await Future.delayed(Duration.zero);

        // Assert
        expect(localeNotifier.state?.languageCode, 'en');
        verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
      },
    );

    test(
      'should fall back to "en" when stored locale is unsupported (es)',
      () async {
        // Arrange
        when(
          mockPrefsService.get<String>(StorageKeys.locale),
        ).thenAnswer((_) async => 'es');

        // Act
        localeNotifier = LocaleNotifier(mockPrefsService);
        await Future.delayed(Duration.zero);

        // Assert
        expect(localeNotifier.state?.languageCode, 'en');
        verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
      },
    );

    test('should default to "en" when stored value is null', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => null);

      // Act
      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Assert
      expect(localeNotifier.state?.languageCode, 'en');
      verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
    });

    test('should default to "en" when stored value is empty string', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => '');

      // Act
      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Assert
      expect(localeNotifier.state?.languageCode, 'en');
      verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
    });

    test(
      'should set locale to "en" when setLocale is called with null',
      () async {
        // Arrange
        when(
          mockPrefsService.get<String>(StorageKeys.locale),
        ).thenAnswer((_) async => 'bo');
        when(
          mockPrefsService.set<String>(StorageKeys.locale, any),
        ).thenAnswer((_) async => true);

        localeNotifier = LocaleNotifier(mockPrefsService);
        await Future.delayed(Duration.zero);

        // Act
        await localeNotifier.setLocale(null);

        // Assert
        expect(localeNotifier.state, null);
        verify(
          mockPrefsService.set<String>(StorageKeys.locale, 'en'),
        ).called(1);
      },
    );

    test(
      'should fall back to "en" when stored value contains invalid characters',
      () async {
        // Arrange
        when(
          mockPrefsService.get<String>(StorageKeys.locale),
        ).thenAnswer((_) async => 'invalid-locale-123');

        // Act
        localeNotifier = LocaleNotifier(mockPrefsService);
        await Future.delayed(Duration.zero);

        // Assert
        expect(localeNotifier.state?.languageCode, 'en');
        verify(mockPrefsService.get<String>(StorageKeys.locale)).called(1);
      },
    );
  });

  group('LocaleNotifier - Edge Cases', () {
    test('should handle storage service failure gracefully', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () => localeNotifier = LocaleNotifier(mockPrefsService),
        returnsNormally,
      );
      // Should use default "en" locale
      expect(localeNotifier.state?.languageCode, 'en');
    });

    test('should handle concurrent locale changes correctly', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'en');
      when(
        mockPrefsService.set<String>(StorageKeys.locale, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Act - Simulate concurrent changes
      final futures = [
        localeNotifier.setLocale(const Locale('bo')),
        localeNotifier.setLocale(const Locale('zh')),
        localeNotifier.setLocale(const Locale('en')),
      ];
      await Future.wait(futures);

      // Assert - Last change should win
      expect(localeNotifier.state?.languageCode, 'en');
      verify(mockPrefsService.set<String>(StorageKeys.locale, any)).called(3);
    });

    test('should verify locale is persisted after setting', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'en');
      when(
        mockPrefsService.set<String>(StorageKeys.locale, 'zh'),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Act
      await localeNotifier.setLocale(const Locale('zh'));

      // Assert
      verify(mockPrefsService.set<String>(StorageKeys.locale, 'zh')).called(1);
      expect(localeNotifier.state?.languageCode, 'zh');
    });

    test('should handle storage set failure gracefully', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'en');
      when(
        mockPrefsService.set<String>(StorageKeys.locale, any),
      ).thenThrow(Exception('Failed to save'));

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Act & Assert - Should update state even if save fails
      await localeNotifier.setLocale(const Locale('bo'));
      expect(localeNotifier.state?.languageCode, 'bo');
    });

    test('should maintain state consistency across multiple changes', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => null);
      when(
        mockPrefsService.set<String>(StorageKeys.locale, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Act - Multiple sequential changes
      expect(localeNotifier.state?.languageCode, 'en');

      await localeNotifier.setLocale(const Locale('bo'));
      expect(localeNotifier.state?.languageCode, 'bo');

      await localeNotifier.setLocale(const Locale('zh'));
      expect(localeNotifier.state?.languageCode, 'zh');

      await localeNotifier.setLocale(const Locale('en'));
      expect(localeNotifier.state?.languageCode, 'en');

      // Assert
      verify(mockPrefsService.set<String>(StorageKeys.locale, any)).called(3);
    });
  });

  group('LocaleNotifier - Integration Scenarios', () {
    test('should handle app restart simulation with valid locale', () async {
      // Arrange - First app session
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => null);
      when(
        mockPrefsService.set<String>(StorageKeys.locale, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);
      await localeNotifier.setLocale(const Locale('bo'));
      localeNotifier.dispose();

      // Arrange - Second app session (restart)
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'bo');

      // Act
      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Assert - Should restore previous locale
      expect(localeNotifier.state?.languageCode, 'bo');
    });

    test(
      'should handle app update scenario where locale becomes unsupported',
      () async {
        // Arrange - Simulate old app version stored unsupported locale
        when(
          mockPrefsService.get<String>(StorageKeys.locale),
        ).thenAnswer((_) async => 'unsupported_old_locale');

        // Act
        localeNotifier = LocaleNotifier(mockPrefsService);
        await Future.delayed(Duration.zero);

        // Assert - Should fall back to default
        expect(localeNotifier.state?.languageCode, 'en');
      },
    );

    test('should handle clear data scenario', () async {
      // Arrange
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => 'bo');
      when(
        mockPrefsService.set<String>(StorageKeys.locale, any),
      ).thenAnswer((_) async => true);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);
      expect(localeNotifier.state?.languageCode, 'bo');
      localeNotifier.dispose();

      // Act - Simulate app data cleared
      when(
        mockPrefsService.get<String>(StorageKeys.locale),
      ).thenAnswer((_) async => null);

      localeNotifier = LocaleNotifier(mockPrefsService);
      await Future.delayed(Duration.zero);

      // Assert - Should use default
      expect(localeNotifier.state?.languageCode, 'en');
    });
  });
}
