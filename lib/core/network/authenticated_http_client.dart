// lib/core/network/authenticated_http_client.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:logging/logging.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Auth0 auth0;
  final Logger _logger = Logger('AuthenticatedHttpClient');

  AuthenticatedHttpClient._internal(this._inner, this.auth0);

  static AuthenticatedHttpClient? _instance;

  factory AuthenticatedHttpClient(http.Client inner, Auth0 auth0) {
    _instance ??= AuthenticatedHttpClient._internal(inner, auth0);
    return _instance!;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add auth header for protected endpoints
    if (_needsAuthentication(request.url.path)) {
      final token = await _getValidToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await _inner.send(request);

    // Handle 401 Unauthorized - token might be expired, try to refresh and retry
    if (response.statusCode == 401 && _needsAuthentication(request.url.path)) {
      _logger.warning('401 Unauthorized - attempting token refresh and retry');

      try {
        final creds = await auth0.credentialsManager.credentials(
          minTtl: 900, // 5 min buffer
        );
        final freshToken = creds.idToken;
        final newRequest = _cloneRequest(request);
        newRequest.headers['Authorization'] = 'Bearer $freshToken';
        _logger.info('Retrying request with refreshed accessToken');
        return await _inner.send(newRequest);
      } catch (e) {
        _logger.severe('Error during token refresh retry: $e');
      }
    }
    return response;
  }

  Future<String?> _getValidToken() async {
    try {
      final credentials = await auth0.credentialsManager.credentials(
        minTtl: 300, // 5 min buffer
      );
      return credentials.idToken;
    } catch (e) {
      _logger.severe('Failed to get valid idToken: $e');
      return null;
    }
  }

  // Helper method to clone a request for retry
  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    http.BaseRequest newRequest;

    if (request is http.Request) {
      newRequest = http.Request(request.method, request.url)
        ..body = request.body;
    } else if (request is http.MultipartRequest) {
      newRequest =
          http.MultipartRequest(request.method, request.url)
            ..fields.addAll(request.fields)
            ..files.addAll(request.files);
    } else {
      throw UnsupportedError(
        'Request type ${request.runtimeType} not supported for cloning',
      );
    }

    // Copy all headers except Authorization (will be added fresh)
    newRequest.headers.addAll(
      Map.from(request.headers)..remove('Authorization'),
    );
    return newRequest;
  }

  bool _needsAuthentication(String path) {
    // Define which endpoints need authentication
    final protectedPaths = ['/api/v1/users/me', '/api/v1/users/me/plans'];

    return protectedPaths.any(
      (protectedPath) => path.startsWith(protectedPath.replaceAll('/*', '')),
    );
  }
}
