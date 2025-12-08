/// Onboarding feature barrel file
/// Exports all onboarding-related screens, widgets, models, and state management
library;

// Models
export 'models/onboarding_preferences.dart';

// Application Layer (State Management)
export 'application/onboarding_state.dart';
export 'application/onboarding_notifier.dart';
export 'application/onboarding_provider.dart';

// Data Layer
export 'data/onboarding_local_datasource.dart';
export 'data/onboarding_remote_datasource.dart';
export 'data/onboarding_repository.dart';
export 'data/providers/onboarding_datasource_providers.dart';

// Presentation Layer - Screens
export 'presentation/onboarding_screen_1.dart';
export 'presentation/onboarding_screen_3.dart';
export 'presentation/onboarding_screen_5.dart';
export 'presentation/onboarding_wrapper.dart';

// Presentation Layer - Shared Widgets
export 'presentation/widgets/onboarding_question_title.dart';
export 'presentation/widgets/onboarding_continue_button.dart';
export 'presentation/widgets/onboarding_radio_option.dart';
export 'presentation/widgets/onboarding_back_button.dart';
