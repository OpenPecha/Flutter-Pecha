# Recitation API Fix

## Date

November 14, 2025

## Issues Fixed

### 1. 404 Error - URL Path Inconsistency

**Problem**: The recitation content endpoint was using `/api/v1/recitations/$id` while other endpoints used just `/recitations`.

**Solution**: Changed the URL from `$baseUrl/api/v1/recitations/$id` to `$baseUrl/recitations/$id` to match the pattern of other endpoints.

**File**: `lib/features/recitation/data/datasource/recitations_remote_datasource.dart`

### 2. 422 Error - Incorrect Request Body Format

**Problem**: The request body wasn't matching the API specification - some fields were conditionally included, and the language was sent as a query parameter instead of in the body.

**Solution**:

- Ensured all fields are always present in the request body (using empty arrays as defaults)
- Moved `language` from query parameter to request body
- Request body now matches API spec exactly:
  ```json
  {
    "language": "string",
    "recitation": ["string"],
    "translations": [],
    "transliterations": [],
    "adaptations": []
  }
  ```

**File**: `lib/features/recitation/data/datasource/recitations_remote_datasource.dart`

### 3. Params Structure Refactoring

**Problem**: Parameters were being passed as a loosely-typed `Map<String, dynamic>`, leading to potential type errors and poor maintainability.

**Solution**:

- Created a typed `RecitationContentParams` class similar to the pattern used in the texts feature
- Updated the provider to use the strongly-typed params class
- Cleaned up the UI code to build params more clearly

**Files**:

- `lib/features/recitation/presentation/providers/recitations_providers.dart`
- `lib/features/recitation/presentation/screens/recitation_detail_screen.dart`

## Changes Summary

### Before

```dart
// Incorrect URL and conditional body fields
final response = await client.post(
  Uri.parse('$baseUrl/api/v1/recitations/$id')
    .replace(queryParameters: {'language': language}),
  body: json.encode({
    if (recitation != null && recitation.isNotEmpty)
      'recitation': recitation,
    // other fields conditionally included...
  }),
);

// Loosely typed params
final contentAsync = ref.watch(recitationContentProvider({
  'text_id': textId,
  'recitations': ['bo'],
}));
```

### After

```dart
// Correct URL with all required fields in body
final response = await client.post(
  Uri.parse('$baseUrl/recitations/$id'),
  body: json.encode({
    'language': language,
    'recitation': recitation ?? [],
    'translations': translations ?? [],
    'transliterations': transliterations ?? [],
    'adaptations': adaptations ?? [],
  }),
);

// Strongly typed params
final params = RecitationContentParams(
  textId: textId,
  recitations: ['bo'],
  translations: ['en'],
);
final contentAsync = ref.watch(recitationContentProvider(params));
```

## Testing

After these changes, test the following scenarios:

1. ✅ Fetch recitation content in Tibetan (bo)
2. ✅ Fetch recitation content in English (en)
3. ✅ Fetch recitation content in Chinese (zh)
4. ✅ Verify correct translations are loaded based on language
5. ✅ Verify transliterations appear for supported languages

## Debug Logging

Added comprehensive debug logging to help diagnose issues:

- Request URL with full query parameters
- Response status codes
- Response body (on error)

These logs can be viewed in the Flutter console when running in debug mode.

## Related Files

- `lib/features/recitation/data/datasource/recitations_remote_datasource.dart`
- `lib/features/recitation/data/repositories/recitations_repository.dart`
- `lib/features/recitation/presentation/providers/recitations_providers.dart`
- `lib/features/recitation/presentation/screens/recitation_detail_screen.dart`
