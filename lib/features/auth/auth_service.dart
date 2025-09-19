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

  // quick logout
  Future<void> quickLogout() async {
    try {
      await auth0.credentialsManager.clearCredentials();
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await auth0
          .webAuthentication(scheme: 'org.pecha.app')
          .logout(useHTTPS: true);
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
  }

  // Add token refresh functionality
  Future<Credentials?> refreshTokens() async {
    try {
      final credentials = await auth0.credentialsManager.credentials(
        minTtl: 900, // 15 minutes
      );
      _logger.info('Token refresh successful');
      return credentials;
    } catch (e) {
      _logger.warning('Token refresh failed: $e');
      return null;
    }
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}
