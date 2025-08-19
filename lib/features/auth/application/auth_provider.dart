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
  AuthNotifier({required this.authService})
    : super(const AuthState(isLoggedIn: false, isLoading: true)) {
    _restoreLoginState();
  }

  Future<void> _restoreLoginState() async {
    try {
      final hasValid =
          await authService.auth0.credentialsManager.hasValidCredentials();
      if (hasValid) {
        final credentials =
            await authService.auth0.credentialsManager.credentials();
        state = state.copyWith(
          isLoggedIn: true,
          userId: credentials.user.sub,
          isLoading: false,
          isGuest: false,
          userProfile: credentials.user,
        );
      } else {
        state = state.copyWith(
          isLoggedIn: false,
          userId: null,
          isLoading: false,
          isGuest: false,
          userProfile: null,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoggedIn: false, userId: null, isLoading: false);
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
        case 'facebook':
          credentials = await authService.loginWithFacebook();
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
    await authService.quickLogout();
    state = state.copyWith(
      isLoggedIn: false,
      userId: null,
      isLoading: false,
      isGuest: false,
      userProfile: null,
    );
  }

  Future<void> checkTokenRefresh() async {
    if (!state.isLoggedIn || state.isGuest) return;

    try {
      if (await authService.needsTokenRefresh()) {
        final success = await authService.refreshTokens();
        if (!success) {
          // Token refresh failed, logout user
          await logout();
        }
      }
    } catch (e) {
      Logger('AuthNotifier').warning('Token refresh check failed: $e');
    }
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

      // Set up periodic token refresh
      Timer.periodic(const Duration(minutes: 5), (timer) {
        if (notifier.mounted) {
          notifier.checkTokenRefresh();
        } else {
          timer.cancel();
        }
      });

      return notifier;
    },
    loading:
        () => AuthNotifier(
          authService: AuthService(domain: 'loading', clientId: 'loading'),
        ),
    error: (err, stack) {
      // Log the error for debugging
      Logger('AuthProvider').severe('Failed to load auth config', err, stack);
      return AuthNotifier(
        authService: AuthService(domain: 'error', clientId: 'error'),
      );
    },
  );
});

final auth0ConfigProvider = FutureProvider<Auth0Config>((ref) async {
  return await fetchAuth0Config();
});
