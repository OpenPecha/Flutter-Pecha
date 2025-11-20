# Multi-Language Font System Guide

## Overview

The app now supports separate fonts for **system UI** and **content** across multiple languages:

- **System Fonts**: Used for UI elements (tabs, navigation, settings, buttons, etc.)
- **Content Fonts**: Used for backend content (texts, practice plans, recitations, etc.)

## Current Configuration

### Tibetan (bo)
- **System**: Google Noto Serif Tibetan
- **Content**: Google Jomolhari

### English (en) & Chinese (zh)
- **System**: Google Inter
- **Content**: Google EB Garamond

### Sanskrit (sa)
- **System**: Google Noto Serif Tibetan
- **Content**: Google Jomolhari

## Architecture

### 1. Font Configuration (`font_config.dart`)

Central configuration file that defines fonts for each language:

```dart
// Get font family name for a language and type
String fontName = AppFontConfig.getFontFamily('bo', FontType.system);
// Returns: 'Noto Serif Tibetan'

// Get TextTheme for system UI
TextTheme theme = AppFontConfig.getTextTheme('bo', FontType.system, Brightness.light);

// Get TextStyle for content
TextStyle? style = AppFontConfig.getContentTextStyle('bo', baseStyle);
```

### 2. App Theme (`app_theme.dart`)

The app theme automatically uses **system fonts** based on the current locale:

```dart
ThemeData theme = AppTheme.lightTheme(Locale('bo'));
// All system UI will use Noto Serif Tibetan for Tibetan
```

### 3. Helper Functions (`shared/utils/helper_functions.dart`)

For content widgets, use these helper functions:

```dart
// Get content font family name
String? fontFamily = getFontFamily('bo'); // Returns 'Jomolhari'

// Get complete TextStyle with content font
TextStyle? style = getContentTextStyle('bo', TextStyle(fontSize: 18));
```

## Usage Examples

### System UI Elements (Automatic)

System UI elements (AppBar, BottomNavigationBar, Buttons, etc.) automatically use the correct system font based on locale:

```dart
// No special handling needed - theme handles it
AppBar(
  title: Text('Title'), // Uses system font automatically
)
```

### Content Widgets (Manual)

For content from backend, explicitly use content fonts. **Both methods work correctly:**

#### Option 1: Using fontFamily parameter (Simple)

```dart
Text(
  'Content from backend',
  style: TextStyle(
    fontFamily: getFontFamily(language), // Returns proper Google Font family name
    fontSize: 18,
  ),
)
```

This works for both Google Fonts and local fonts. The `getFontFamily()` function now returns the actual Google Font family name that can be used directly.

#### Option 2: Using getContentTextStyle (Recommended for more control)

```dart
Text(
  'Content from backend',
  style: getContentTextStyle(
    language,
    TextStyle(fontSize: 18, color: Colors.black),
  ),
)
```

This method is recommended when you need more control over the TextStyle, as it properly applies all Google Fonts features and optimizations.

#### Option 3: HTML Widget

```dart
Html(
  data: htmlContent,
  style: {
    "body": Style(
      fontSize: FontSize(18),
      fontFamily: getFontFamily(language), // Content font
    ),
  },
)
```

### Direct Access to Font Config

```dart
import 'package:flutter_pecha/core/theme/font_config.dart';

// Get system font for Tibetan
String systemFont = AppFontConfig.getFontFamily('bo', FontType.system);

// Get content font for English
String contentFont = AppFontConfig.getFontFamily('en', FontType.content);

// Get all supported languages
List<String> languages = AppFontConfig.supportedLanguages;
```

## Adding New Languages

To add a new language, update `font_config.dart`:

```dart
static const Map<String, LanguageFontConfig> _languageFonts = {
  // ... existing languages ...

  // New language
  'hi': LanguageFontConfig(
    systemFont: 'Roboto',           // For UI elements
    contentFont: 'Noto Serif Devanagari', // For content
    systemFontIsGoogle: true,
    contentFontIsGoogle: true,
  ),
};
```

### For Local Fonts

If you need to use local fonts (from assets):

```dart
'bo': LanguageFontConfig(
  systemFont: 'MonlamTibetan',
  contentFont: 'TsumachuTibetan',
  systemFontIsGoogle: false,    // Set to false for local fonts
  contentFontIsGoogle: false,
),
```

Then add the font to `pubspec.yaml`:

```yaml
fonts:
  - family: TsumachuTibetan
    fonts:
      - asset: assets/fonts/Tsumachu.ttf
```

## Testing

To test the font system:

1. **System UI**: Change app locale and verify UI elements use the correct system font
2. **Content**: Verify content widgets (texts, recitations) use the correct content font
3. **Multiple Languages**: Test switching between different languages

## Notes

- Google Fonts are downloaded on-demand and cached automatically
- System fonts are applied globally through the theme
- Content fonts must be explicitly set in content widgets
- Fallback to Inter/EB Garamond for unknown languages
- Line heights and font sizes remain in `helper_functions.dart` for now

## Migration from Old System

### Before
```dart
String? fontFamily = getFontFamily(language); // Mixed system/content
```

### After
```dart
// For UI elements - handled automatically by theme
// For content elements - same function, now returns content font
String? fontFamily = getFontFamily(language);
```

The `getFontFamily()` helper function now:
1. Returns **content fonts** by default (system fonts are handled by theme)
2. Returns the actual Google Font family name that works with `TextStyle(fontFamily: ...)`
3. Works for both Google Fonts and local fonts

**Technical Detail**: For Google Fonts, the function calls the GoogleFonts API (e.g., `GoogleFonts.jomolhari()`) to get the proper font family name, ensuring the font is loaded and available. This is why both `getFontFamily()` and `getContentTextStyle()` now work correctly.
