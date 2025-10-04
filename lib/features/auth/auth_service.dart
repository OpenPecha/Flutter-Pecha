import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:logging/logging.dart';

class AuthService {
  late final Auth0 auth0;
  final Logger _logger = Logger('AuthService');

  // Accept config as parameter
  AuthService({required String domain, required String clientId}) {
    auth0 = Auth0(domain, clientId);
  }

  // Common login method
  Future<Credentials?> _loginWithConnection(
    String connection, [
    Map<String, String>? additionalParameters,
  ]) async {
    try {
      final parameters = {"connection": connection};
      if (additionalParameters != null) {
        parameters.addAll(additionalParameters);
      }

      final credentials = await auth0
          .webAuthentication(scheme: 'org.pecha.app')
          .login(
            useHTTPS: true,
            parameters: parameters,
            scopes: {"openid", "profile", "email", "offline_access"},
          );

      // Store credentials in the credentials manager
      await auth0.credentialsManager.storeCredentials(credentials);

      _logger.info('Login successful for connection: $connection');
      return credentials;
    } on WebAuthenticationException catch (e) {
      _logger.severe('WebAuth error for $connection: ${e.message}');
      if (e.code == 'a0.session.user_cancelled') {
        throw AuthException('Login was cancelled by user', code: e.code);
      }
      throw AuthException('Login failed: ${e.message}', code: e.code);
    } catch (e) {
      _logger.severe('Unexpected login error for $connection: $e');
      throw AuthException('An unexpected error occurred during login');
    }
  }

  // Login with Google
  Future<Credentials?> loginWithGoogle() async {
    return _loginWithConnection('google-oauth2', {'prompt': 'select_account'});
  }

  // Login with Apple
  Future<Credentials?> loginWithApple() async {
    return _loginWithConnection('apple');
  }

  // Local logout - clears credentials from device only
  Future<void> localLogout() async {
    try {
      await auth0.credentialsManager.clearCredentials();
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
  }

  // Global logout - clears credentials from device and server
  Future<void> globalLogout() async {
    try {
      await auth0
          .webAuthentication(scheme: 'org.pecha.app')
          .logout(useHTTPS: true);
      await auth0.credentialsManager.clearCredentials();
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
  }

  /// Decode and check if ID token is expired
  bool _isIdTokenExpired(String idToken) {
    final parts = idToken.split('.');
    if (parts.length != 3) return true;

    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload) as Map<String, dynamic>;

    final exp = claims['exp'] as int;
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);

    return DateTime.now().isAfter(
      expiryDate.subtract(const Duration(minutes: 2)),
    );
  }

  /// Force refresh ID token using refresh token
  Future<String?> _refreshIdToken() async {
    final storedCreds = await auth0.credentialsManager.credentials();
    if (storedCreds.refreshToken == null) {
      throw Exception("No refresh token available.");
    }

    final newCreds = await auth0.api.renewCredentials(
      refreshToken: storedCreds.refreshToken!,
    );
    await auth0.credentialsManager.storeCredentials(newCreds);
    return newCreds.idToken;
  }

  /// Public method to always return a valid ID token
  Future<String?> getValidIdToken() async {
    final creds = await auth0.credentialsManager.credentials();
    if (_isIdTokenExpired(creds.idToken)) {
      final newToken = await _refreshIdToken();
      if (newToken == null) {
        throw Exception("Failed to refresh ID token");
      }
      return newToken;
    }
    return creds.idToken;
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}
