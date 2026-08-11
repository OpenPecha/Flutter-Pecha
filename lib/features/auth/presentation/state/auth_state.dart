// Authentication state
//
// Handles ONLY authentication concerns:
// - Login/logout status
// - Guest mode
// - Auth loading states
// - Auth errors
// - Onboarding completion (fetched once at login, owned here to avoid
//   per-navigation network calls in the route guard)
//
// User profile data is now managed by UserNotifier (userProvider)

// Sentinel used by copyWith so callers can explicitly pass null for
// hasCompletedOnboarding without it being treated as "keep current value".
const _kSentinel = Object();

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? errorMessage;

  /// null  = not yet known (offline, fetch failed, or retry pending).
  /// true  = onboarding completed.
  /// false = onboarding not completed.
  ///
  /// The route guard reads this synchronously. Unknown status fail-opens to
  /// home; [AuthNotifier] retries the fetch in the background.
  final bool? hasCompletedOnboarding;

  /// null  = not yet known (offline, fetch failed, or retry pending).
  /// true  = first/last name are present (see [User.hasCompleteName]).
  /// false = profile is missing a name — e.g. a brand-new phone/OTP signup —
  ///         and the route guard should route to the complete-profile screen.
  ///
  /// Same fetched-once-at-login, fail-open-on-unknown pattern as
  /// [hasCompletedOnboarding].
  final bool? hasCompleteProfile;

  const AuthState({
    required this.isLoggedIn,
    this.isGuest = false,
    this.isLoading = false,
    this.errorMessage,
    this.hasCompletedOnboarding,
    this.hasCompleteProfile,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? isGuest,
    String? errorMessage,
    // Use _kSentinel as default so passing null explicitly resets the field to
    // null rather than being treated as "no change".
    Object? hasCompletedOnboarding = _kSentinel,
    Object? hasCompleteProfile = _kSentinel,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isLoading: isLoading ?? this.isLoading,
    isGuest: isGuest ?? this.isGuest,
    errorMessage: errorMessage,
    hasCompletedOnboarding: identical(hasCompletedOnboarding, _kSentinel)
        ? this.hasCompletedOnboarding
        : hasCompletedOnboarding as bool?,
    hasCompleteProfile: identical(hasCompleteProfile, _kSentinel)
        ? this.hasCompleteProfile
        : hasCompleteProfile as bool?,
  );

  AuthState clearError() => copyWith(errorMessage: '');
}
