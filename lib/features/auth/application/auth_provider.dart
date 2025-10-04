// Riverpod provider and logic for authentication state.
import 'dart:async';
import 'dart:convert';

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
  final Logger _logger = Logger('AuthNotifier');

  AuthNotifier({required this.authService})
    : super(const AuthState(isLoggedIn: false, isLoading: false)) {
    _restoreLoginState();
  }

  // Decode JWT idToken and return exp (seconds since epoch), or null if unavailable
  int? _parseJwtExp(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = json.decode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) return exp;
      if (exp is num) return exp.toInt();
      return null;
    } catch (e) {
      _logger.warning('Failed to parse idToken exp: $e');
      return null;
    }
  }

  Future<void> _restoreLoginState() async {
    state = state.copyWith(isLoading: true);

    try {
      // First check if we have any credentials at all
      final hasCredentials =
          await authService.auth0.credentialsManager.hasValidCredentials();

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

      // Try to get valid credentials.
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
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      userId: 'guest',
      isGuest: true,
      userProfile: null,
    );
  }

  Future<void> logout() async {
    await authService.localLogout();
    state = state.copyWith(
      isLoggedIn: false,
      userId: null,
      isLoading: false,
      isGuest: false,
      userProfile: null,
    );
  }
}

// Helper classes for loading and error states
class LoadingAuthNotifier extends AuthNotifier {
  LoadingAuthNotifier()
    : super(authService: AuthService(domain: 'temp', clientId: 'temp')) {
    // Don't call _restoreLoginState() as this is just a temporary loading state
    // The actual AuthNotifier will handle state restoration when config loads
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
