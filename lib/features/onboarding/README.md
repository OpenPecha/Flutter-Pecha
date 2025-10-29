# Onboarding Feature

Welcome screens shown to first-time users before they access the main app. Includes 5 screens: 1 welcome screen, 3 questionnaire screens, and 1 completion screen.

## Architecture

This feature follows clean architecture with Riverpod state management:

```
onboarding/
├── application/                    # State Management Layer
│   ├── onboarding_state.dart      # State model
│   ├── onboarding_notifier.dart   # Business logic
│   └── onboarding_provider.dart   # Riverpod provider
├── data/                           # Data Layer
│   ├── onboarding_local_datasource.dart   # SharedPreferences
│   ├── onboarding_remote_datasource.dart  # API calls
│   ├── onboarding_repository.dart         # Aggregates datasources
│   └── providers/
│       └── onboarding_datasource_providers.dart
├── models/
│   └── onboarding_preferences.dart # Data model
├── presentation/                   # UI Layer
│   ├── widgets/                    # Shared widgets
│   │   ├── onboarding_question_title.dart
│   │   ├── onboarding_continue_button.dart
│   │   ├── onboarding_radio_option.dart
│   │   ├── onboarding_checkbox_option.dart
│   │   └── onboarding_back_button.dart
│   ├── onboarding_screen_1.dart   # Welcome screen
│   ├── onboarding_screen_2.dart   # Buddhist familiarity
│   ├── onboarding_screen_3.dart   # Language preference
│   ├── onboarding_screen_4.dart   # Buddhist path
│   ├── onboarding_screen_5.dart   # Completion
│   └── onboarding_wrapper.dart    # PageView coordinator
└── onboarding.dart                 # Barrel file
```

## Design

Based on Figma design: [WeBuddhist-App](https://www.figma.com/design/0TE5qdViUvrisFZfNqODpX/WeBuddhist-App)

### Screen 1 - "Welcome to WeBuddhist" (node-id=127-147)

**Visual Elements:**

- Title: "Welcome to WeBuddhist" (32px, Extra Bold)
- Subtitle: "Where we learn, live, and share Buddhist wisdom every day"
- Logo: Centered with 3 concentric circles in primary red shades
- Quote: Buddhism statistic about 500 million practitioners
- CTA Button: "Find your Peace"

### Screen 2 - Buddhist Familiarity (node-id=380-293)

**Question:** "How familiar are you with Buddhist principles?"

**Options:**

- I'm completely new
- I know a little
- I am a practicing Buddhist

### Screen 3 - Language Preference (node-id=127-166)

**Question:** "In which language would you like to access core texts?"

**Options:**

- Tibetan
- English
- Sanskrit
- Chinese

### Screen 4 - Buddhist Path (node-id=127-154)

**Question:** "Which path or school do you feel drawn to?"

**Subtitle:** "Choose upto 3 options"

**Options:**

- Theravada
- Zen
- Tibetan Buddhism
- Pure land

### Screen 5 - Completion (node-id=127-173)

**Visual Elements:**

- Animated check icon
- Title: "You are All Setup"
- Subtitle: "Welcome To WeBuddhist"
- Auto-submits preferences and navigates

## State Management

### Riverpod Architecture

The feature uses Riverpod `StateNotifier` for state management:

```dart
// Access state
final familiarityLevel = ref.watch(
  onboardingProvider.select((state) => state.preferences.familiarityLevel),
);

// Update state
ref.read(onboardingProvider.notifier).setFamiliarityLevel('completely_new');

// Navigate
ref.read(onboardingProvider.notifier).goToNextPage();
```

### State Flow

1. **User selects option** → Screen calls notifier method → State updates → UI rebuilds
2. **User clicks continue** → Preferences saved locally → Page navigation
3. **Screen 5 completion** → `submitPreferences()` → Save local + attempt remote → Navigate to login

### OnboardingState Model

```dart
class OnboardingState {
  final OnboardingPreferences preferences;  // User selections
  final int currentPage;                    // Current screen index (0-4)
  final bool isLoading;                     // Backend submission status
  final String? error;                      // Error message if any
}
```

## Local Persistence

### Storage Strategy

- **After each questionnaire screen:** Preferences automatically saved to SharedPreferences
- **On app restart:** Preferences loaded from storage (allows resume)
- **On completion:** Marked with completion flag

### Storage Keys

```dart
StorageKeys.onboardingPreferences  // JSON string of preferences
StorageKeys.onboardingCompleted    // Boolean completion flag
```

### Usage

```dart
// Check if completed
final hasCompleted = await repository.hasCompletedOnboarding();

// Load saved preferences
final prefs = await repository.loadPreferences();

// Clear all data
await repository.clearPreferences();
```

## Backend Integration

### API Endpoint (Prepared for Implementation)

**Endpoint:** `POST /api/v1/users/me/onboarding-preferences`

**Headers:**

```
Authorization: Bearer {idToken}
Content-Type: application/json
```

**Request Body:**

```json
{
  "familiarityLevel": "completely_new",
  "preferredLanguage": "tibetan",
  "selectedPaths": ["zen", "tibetan_buddhism"]
}
```

**Response:** `200 OK` or `201 Created`

**Note:** Backend implementation is required. The datasource is ready and will gracefully handle failures by keeping preferences in local storage.

### Error Handling

- Remote save failures are logged but don't block user flow
- Preferences remain in local storage for potential retry
- User sees completion screen regardless of backend status

## Shared Widgets

### Benefits

- **Consistency:** Same styling across all questionnaire screens
- **Maintainability:** Single source of truth for UI components
- **Reusability:** Easy to add new questionnaire screens
- **Code reduction:** ~40% less code duplication

### Available Widgets

1. **OnboardingQuestionTitle** - Title text for questions
2. **OnboardingContinueButton** - Enabled/disabled continue button
3. **OnboardingRadioOption** - Single-select circular radio button
4. **OnboardingCheckboxOption** - Multi-select circular checkbox
5. **OnboardingBackButton** - Back navigation button

### Example Usage

```dart
// Title
OnboardingQuestionTitle(
  title: 'How familiar are you\nwith Buddhist\nprinciples?',
)

// Radio button
OnboardingRadioOption(
  id: 'option_id',
  label: 'Option Label',
  selectedId: currentSelection,
  onSelect: (id) => handleSelect(id),
)

// Continue button
OnboardingContinueButton(
  onPressed: () => handleContinue(),
  isEnabled: selectionMade,
)
```

## Navigation

### Route Access

```dart
// Navigate to onboarding
context.go(RouteConfig.onboarding);
// or
context.go('/onboarding');
```

### Skip Functionality

Users can skip onboarding on screens 1-4 using the "Skip" button in top-right corner. This navigates directly to login.

### Navigation Flow

```
Screen 1 (Welcome) → [Find your Peace]
    ↓
Screen 2 (Familiarity) → [Continue]
    ↓
Screen 3 (Language) → [Continue]
    ↓
Screen 4 (Path) → [Continue]
    ↓
Screen 5 (Completion) → [Auto-navigate after 2s]
    ↓
Login Screen
```

Back navigation available on screens 2-4.

## User Preferences Model

```dart
class OnboardingPreferences {
  final String? familiarityLevel;    // 'completely_new', 'know_little', 'practicing_buddhist'
  final String? preferredLanguage;   // 'tibetan', 'english', 'sanskrit', 'chinese'
  final List<String>? selectedPaths; // ['theravada', 'zen', 'tibetan_buddhism', 'pure_land']
}
```

### Constants

```dart
// Familiarity levels
FamiliarityLevel.completelyNew
FamiliarityLevel.knowLittle
FamiliarityLevel.practicingBuddhist

// Languages
PreferredLanguage.tibetan
PreferredLanguage.english
PreferredLanguage.sanskrit
PreferredLanguage.chinese

// Buddhist paths
BuddhistPath.theravada
BuddhistPath.zen
BuddhistPath.tibetanBuddhism
BuddhistPath.pureLand
```

## Testing

### Manual Testing

1. Navigate to `/onboarding`
2. Complete questionnaire, verify state updates
3. Use back button, verify preferences persist
4. Skip onboarding, verify navigation
5. Complete flow, verify submission (check logs)
6. Restart app, verify preferences loaded

### Integration Points

- Auth flow: Redirect new users to onboarding
- Profile: Display saved preferences
- Content: Use language preference for texts

## Future Enhancements

- [ ] Add unit tests for OnboardingNotifier
- [ ] Add widget tests for each screen
- [ ] Add integration test for full flow
- [ ] Backend API implementation
- [ ] Retry mechanism for failed remote saves
- [ ] Add localization (l10n) for all screens
- [ ] Analytics tracking for completion rate
- [ ] A/B testing for onboarding variations
- [ ] Add more questionnaire screens
- [ ] Personalized content based on preferences
