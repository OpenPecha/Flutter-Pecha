// Riverpod provider and logic for authentication state.
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_service.dart';
import 'package:flutter_pecha/features/auth/application/auth0_config.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final bool isGuest;
  final String? userId;
  final UserProfile? userProfile;

  const AuthState({
    required this.isLoggedIn,
    this.isGuest = false,
    this.userId,
    this.isLoading = false,
    this.userProfile,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userId,
    bool? isLoading,
    bool? isGuest,
    UserProfile? userProfile,
  }) => AuthState(
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    userId: userId ?? this.userId,
    isLoading: isLoading ?? this.isLoading,
    isGuest: isGuest ?? this.isGuest,
    userProfile: userProfile ?? this.userProfile,
  );
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
    state = state.copyWith(isLoading: true);
    Credentials? credentials;
    if (connection == 'google') {
      credentials = await authService.loginWithGoogle();
    } else if (connection == 'facebook') {
      credentials = await authService.loginWithFacebook();
    } else if (connection == 'apple') {
      credentials = await authService.loginWithApple();
    }
    if (credentials != null) {
      state = state.copyWith(
        isLoggedIn: true,
        userId: credentials.user.sub,
        isLoading: false,
        isGuest: false,
        userProfile: credentials.user,
      );
    } else {
      state = state.copyWith(isLoading: false);
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final configAsync = ref.watch(auth0ConfigProvider);
  return configAsync.when(
    data:
        (config) => AuthNotifier(
          authService: AuthService(
            domain: config.domain,
            clientId: config.clientId,
          ),
        ),
    loading:
        () => AuthNotifier(authService: AuthService(domain: '', clientId: '')),
    error:
        (err, stack) =>
            AuthNotifier(authService: AuthService(domain: '', clientId: '')),
  );
});

final auth0ConfigProvider = FutureProvider<Auth0Config>((ref) async {
  return await fetchAuth0Config();
});
