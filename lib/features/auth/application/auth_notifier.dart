// Riverpod provider and logic for authentication state.
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/application/user_notifier.dart';
import 'package:flutter_pecha/features/onboarding/data/providers/onboarding_datasource_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_service.dart';

/// Authentication state
///
/// Handles ONLY authentication concerns:
/// - Login/logout status
/// - Guest mode
/// - Auth loading states
/// - Auth errors
///
/// User profile data is now managed by UserNotifier (userProvider)
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? errorMessage;

  const AuthState({
    required this.isLoggedIn,
    this.isGuest = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    bool? isGuest,
    String? errorMessage,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    isLoading: isLoading ?? this.isLoading,
    isGuest: isGuest ?? this.isGuest,
    errorMessage: errorMessage,
  );

  AuthState clearError() => copyWith(errorMessage: '');
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  final Ref ref;
  final _logger = AppLogger('AuthNotifier');

  AuthNotifier({required this.authService, required this.ref})
    : super(const AuthState(isLoggedIn: false, isLoading: true)) {
    _restoreLoginState();
  }

  Future<void> _restoreLoginState() async {
    _logger.debug('Restoring login state');
    try {
      await authService.initialize(); // Ensure config + Auth0 initialized

      // First check if we have any credentials at all
      final hasCredentials = await authService.hasValidCredentials();
      _logger.debug('Credentials valid: $hasCredentials');

      if (hasCredentials) {
        final credentials =
            await authService.getCredentials(); // 5 minute buffer

        // Validate credentials were actually retrieved
        if (credentials != null && credentials.user.sub.isNotEmpty) {
          state = state.copyWith(
            isLoggedIn: true,
            isLoading: false,
            isGuest: false,
            errorMessage: null,
          );
          _logger.info('Login state restored for user: ${credentials.user.sub}');

          // Initialize user data
          try {
            await ref.read(userProvider.notifier).initializeUser();
          } catch (e) {
            _logger.warning('Could not initialize user data', e);
            // Non-critical, user can still use the app
          }

          // Early return after successful credential restoration
          return;
        } else {
          _logger.debug('Credentials check returned null or invalid user');
          // Fall through to check guest mode
        }
      }

      _logger.debug('No valid credentials found, checking guest mode');

      // No credentials, check if user previously chose guest mode
      final isGuest = await authService.isGuestMode();

      if (isGuest) {
        // Restore guest mode
        state = state.copyWith(
          isLoggedIn: true,
          isLoading: false,
          isGuest: true,
          errorMessage: null,
        );
        _logger.info('Guest mode restored from preferences');
        return;
      }

      // No credentials and not guest mode, user needs to log in
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        isGuest: false,
      );
      _logger.info('No valid credentials or guest mode found, showing login');
    } on CredentialsManagerException catch (e) {
      _logger.error('Credentials manager error during restore: ${e.message}');

      // Clear any stored credentials and require re-authentication
      await _handleAuthFailure();
    } catch (e) {
      _logger.error('Failed to restore login state', e);
      // Clear any stored credentials and require re-authentication
      await _handleAuthFailure();
    }
  }

  Future<void> _handleAuthFailure() async {
    try {
      await authService.localLogout();
    } catch (logoutError) {
      _logger.warning(
        'Failed to clear credentials during logout: $logoutError',
      );
    }

    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      isGuest: false,
    );
  }

  Future<void> login({String? connection}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      Credentials? credentials;

      switch (connection) {
        case 'google':
          credentials = await authService.loginWithGoogle();
          break;
        case 'apple':
          credentials = await authService.loginWithApple();
          break;
        default:
          throw Exception('Unsupported login method: $connection');
      }

      if (credentials != null) {
        // Check if user was previously in guest mode
        final wasGuest = state.isGuest || await authService.isGuestMode();

        // Clear guest mode when user authenticates
        await authService.clearGuestMode();

        // If user was a guest, clear onboarding completion so they see onboarding
        if (wasGuest) {
          try {
            final onboardingRepo = ref.read(onboardingRepositoryProvider);
            await onboardingRepo.clearPreferences();
            _logger.info('Guest converted to authenticated user, onboarding reset');
          } catch (e) {
            _logger.warning('Failed to clear guest onboarding', e);
          }
        }

        state = state.copyWith(
          isLoggedIn: true,
          isLoading: false,
          isGuest: false,
          errorMessage: null,
        );
        _logger.info('User authenticated, guest mode cleared');

        // Fetch and save user data from backend on first login
        try {
          await ref.read(userProvider.notifier).initializeUser();
          _logger.info('User data fetched and saved locally');
        } catch (e) {
          _logger.warning('Failed to fetch user data: $e');
          // Don't fail the login if user data fetch fails
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login was cancelled or failed',
        );
      }
    } catch (e) {
      _logger.error('Login failed', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  // continue as guest
  Future<void> continueAsGuest() async {
    // Persist guest mode preference
    await authService.saveGuestMode();

    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      isGuest: true,
    );
    _logger.info('Guest mode activated and persisted');
  }

  Future<void> logout() async {
    await authService.localLogout(); // This also clears guest mode

    // Clear user data on logout
    await ref.read(userProvider.notifier).clearUser();

    state = state.copyWith(
      isLoggedIn: false,
      isLoading: false,
      isGuest: false,
    );

    _logger.info('User logged out, auth and user state cleared');
  }

  /// Completely clear all user data (use for account deletion or privacy reset)
  Future<void> clearAllUserData() async {
    try {
      await ref.read(userProvider.notifier).clearUser();

      // Also clear onboarding preferences for complete reset
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await onboardingRepo.clearPreferences();

      _logger.info('All user data and onboarding preferences cleared');
    } catch (e) {
      _logger.warning('Failed to clear user data: $e');
    }
  }

  /// Reset onboarding status (for testing or manual reset)
  /// This allows a user to go through onboarding again
  Future<void> resetOnboarding() async {
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      await onboardingRepo.clearPreferences();
      _logger.info('Onboarding status reset - user will see onboarding on next navigation');
    } catch (e) {
      _logger.warning('Failed to reset onboarding: $e');
    }
  }
}

// Helper classes for loading and error states
// class LoadingAuthNotifier extends AuthNotifier {
//   LoadingAuthNotifier()
//     : super(authService: AuthService(domain: 'temp', clientId: 'temp')) {
//     // Don't call _restoreLoginState() as this is just a temporary loading state
//     // The actual AuthNotifier will handle state restoration when config loads
//     state = const AuthState(isLoggedIn: false, isLoading: true);
//   }
// }

// class ErrorAuthNotifier extends AuthNotifier {
//   ErrorAuthNotifier(String errorMessage)
//     : super(authService: AuthService(domain: 'temp', clientId: 'temp')) {
//     state = AuthState(
//       isLoggedIn: false,
//       isLoading: false,
//       errorMessage: errorMessage,
//     );
//   }
// }

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService.instance; // Use singleton
  return AuthNotifier(authService: authService, ref: ref);
});
