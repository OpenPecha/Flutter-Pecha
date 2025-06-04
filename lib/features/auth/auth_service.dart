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
      final parameters = {'connection': connection};
      if (additionalParameters != null) {
        parameters.addAll(additionalParameters);
      }
      final credentials = await auth0
          .webAuthentication(scheme: 'org.pecha.app')
          .login(parameters: parameters);
      return credentials;
    } catch (e) {
      _logger.severe('Login failed: $e');
      return null;
    }
  }

  // Login with Google
  Future<Credentials?> loginWithGoogle() async {
    return _loginWithConnection('google-oauth2', {'prompt': 'select_account'});
  }

  // Login with Facebook
  Future<Credentials?> loginWithFacebook() async {
    return _loginWithConnection('facebook');
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
      await auth0.webAuthentication(scheme: 'org.pecha.app').logout();
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }
  }
}
