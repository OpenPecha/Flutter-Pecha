# Locale Provider Tests

This directory contains comprehensive unit tests for the locale persistence functionality.

## Test Coverage

The test suite includes **21 test cases** covering:

### Valid Scenarios (6 tests)

- Loading valid stored locales (en, bo, zh)
- Setting and persisting new locale
- Default locale on first launch
- Locale persistence verification

### Invalid Scenarios (7 tests)

- Unsupported locale codes (fr, de, es, etc.)
- Null/empty stored values
- Invalid characters in stored locale
- Setting null locale

### Edge Cases (5 tests)

- Storage service failures
- Concurrent locale changes
- Storage set failures
- State consistency across multiple changes

### Integration Scenarios (3 tests)

- App restart simulation
- App update with unsupported locale
- Clear data scenario

## When Locally Stored Locale is Invalid

The locally stored locale becomes **invalid** in the following scenarios:

1. **Unsupported language code** - Locale not in `['en', 'bo', 'zh']`
2. **First app launch** - No stored value exists
3. **Corrupted data** - Wrong type or malformed data
4. **Storage cleared** - User clears app data/cache
5. **App updates** - Supported locales change between versions
6. **Storage service failure** - SharedPreferences unavailable

### Fallback Behavior

When any invalid scenario occurs, the app:

1. Falls back to default "en" locale
2. Continues to function normally
3. Does not crash or show errors to user
4. Validates against `L10n.all` supported locales

## Running Tests

```bash
# Run all locale provider tests
flutter test test/core/config/locale_provider_test.dart

# Generate mock files (if needed)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Dependencies

- `mockito`: For mocking `PreferencesService`
- `build_runner`: For generating mock classes
- `flutter_test`: Flutter testing framework

## Implementation Details

The `LocaleNotifier` class:

- Validates stored locale against supported locales
- Handles storage failures gracefully with try-catch
- Maintains UI state even if persistence fails
- Uses SharedPreferences for local storage
