// Riverpod provider and logic for authentication state.
import 'dart:async';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../auth_service.dart';
import 'package:flutter_pecha/features/auth/application/auth0_config.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? userId;
  final UserProfile? userProfile;
  final String? errorMessage; // Add error state

  const AuthState({
    required this.isLoggedIn,
    this.isGuest = false,
    this.userId,
    this.isLoading = false,
    this.userProfile,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    bool? isLoading,
    bool? isGuest,
    UserProfile? userProfile,
    String? errorMessage,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    userId: userId ?? this.userId,
    isLoading: isLoading ?? this.isLoading,
    isGuest: isGuest ?? this.isGuest,
    userProfile: userProfile ?? this.userProfile,
    errorMessage: errorMessage,
  );

  AuthState clearError() => copyWith(errorMessage: '');
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  Timer? _refreshTimer;
  final Logger _logger = Logger('AuthNotifier');

  AuthNotifier({required this.authService})
    : super(const AuthState(isLoggedIn: false, isLoading: false)) {
    _restoreLoginState();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 30), // Refresh every 30 minutes
      (_) => refreshTokens(),
    );
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    super.dispose();
  }

  Future<void> _restoreLoginState() async {
    state = state.copyWith(isLoading: true);

    try {
      // First check if we have any credentials at all
      final hasCredentials = await authService.auth0.credentialsManager
          .hasValidCredentials(minTtl: 0); // Check if any credentials exist

      if (!hasCredentials) {
        // No credentials at all, user needs to log in
        state = state.copyWith(
          isLoggedIn: false,
          userId: null,
          isLoading: false,
          isGuest: false,
          userProfile: null,
        );
        return;
      }

      // Try to get valid credentials with a reasonable buffer
      final credentials = await authService.auth0.credentialsManager
          .credentials(minTtl: 300); // 5 minute buffer

      state = state.copyWith(
        isLoggedIn: true,
        userId: credentials.user.sub,
        isLoading: false,
        isGuest: false,
        userProfile: credentials.user,
        errorMessage: null,
      );

      // Start timer after successful restore
      _startRefreshTimer();
    } catch (e) {
      _logger.severe('Failed to restore login state: $e');

      // If we get here, it means tokens are expired or invalid
      // Clear any stored credentials and require re-authentication
      try {
        await authService.localLogout();
      } catch (logoutError) {
        _logger.warning(
          'Failed to clear credentials during logout: $logoutError',
        );
      }

      state = state.copyWith(
        isLoggedIn: false,
        userId: null,
        isLoading: false,
        isGuest: false,
        userProfile: null,
        errorMessage: 'Session expired. Please log in again.',
      );
    }
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
        state = state.copyWith(
          isLoggedIn: true,
          userId: credentials.user.sub,
          isLoading: false,
          isGuest: false,
          userProfile: credentials.user,
          errorMessage: null,
        );
        // ✅ START timer after successful login
        _startRefreshTimer();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login was cancelled or failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  // continue as guest
  Future<void> continueAsGuest() async {
    // ✅ STOP timer for guest users (they don't need token refresh)
    _stopRefreshTimer();
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      userId: 'guest',
      isGuest: true,
      userProfile: null,
    );
  }

  Future<void> logout() async {
    // ✅ STOP timer before logout
    _stopRefreshTimer();
    await authService.localLogout();
    state = state.copyWith(
      isLoggedIn: false,
      userId: null,
      isLoading: false,
      isGuest: false,
      userProfile: null,
    );
  }

  // Enhanced refresh method that handles expired tokens better
  Future<void> refreshTokens() async {
    if (state.isGuest || !state.isLoggedIn) return;

    try {
      final credentials = await authService.refreshTokens();
      if (credentials != null) {
        state = state.copyWith(
          userProfile: credentials.user,
          errorMessage: null,
        );
        _logger.info('Token refresh successful');
      } else {
        // Token refresh failed, user needs to re-authenticate
        _stopRefreshTimer();
        await authService.localLogout(); // Clear stored credentials

        state = state.copyWith(
          isLoggedIn: false,
          userId: null,
          isGuest: false,
          userProfile: null,
          errorMessage: 'Session expired. Please log in again.',
        );
        _logger.warning('Token refresh failed - user needs to re-authenticate');
      }
    } catch (e) {
      _logger.severe('Token refresh error: $e');

      // On error, stop the timer and require re-authentication
      _stopRefreshTimer();
      await authService.localLogout();

      state = state.copyWith(
        isLoggedIn: false,
        userId: null,
        isGuest: false,
        userProfile: null,
        errorMessage: 'Session expired. Please log in again.',
      );
    }
  }

  // Method to handle API errors that might indicate expired tokens
  void handleApiError(int statusCode) {
    if (statusCode == 401 && state.isLoggedIn && !state.isGuest) {
      _logger.warning('API returned 401 - triggering token refresh');
      refreshTokens();
    }
  }
}

// Helper classes for loading and error states
class LoadingAuthNotifier extends AuthNotifier {
  LoadingAuthNotifier()
    : super(authService: AuthService(domain: 'temp', clientId: 'temp')) {
    state = const AuthState(isLoggedIn: false, isLoading: true);
  }
}

class ErrorAuthNotifier extends AuthNotifier {
  ErrorAuthNotifier(String errorMessage)
    : super(authService: AuthService(domain: 'temp', clientId: 'temp')) {
    state = AuthState(
      isLoggedIn: false,
      isLoading: false,
      errorMessage: errorMessage,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final configAsync = ref.watch(auth0ConfigProvider);
  return configAsync.when(
    data: (config) {
      final authService = AuthService(
        domain: config.domain,
        clientId: config.clientId,
      );
      final notifier = AuthNotifier(authService: authService);
      return notifier;
    },
    loading: () {
      // Return a temporary notifier with loading state
      return LoadingAuthNotifier();
    },
    error: (err, stack) {
      // Log the error for debugging
      Logger('AuthProvider').severe('Failed to load auth config', err, stack);
      return ErrorAuthNotifier('Failed to load authentication configuration');
    },
  );
});

final auth0ConfigProvider = FutureProvider<Auth0Config>((ref) async {
  return await fetchAuth0Config();
});
