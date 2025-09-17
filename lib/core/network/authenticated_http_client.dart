// lib/core/network/authenticated_http_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:logging/logging.dart';

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Auth0 auth0;
  final Logger _logger = Logger('AuthenticatedHttpClient');

  String? _cachedToken;
  DateTime? _tokenExpiry;

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
      _cachedToken = null;
      _tokenExpiry = null;

      // Try to get a fresh token and retry the request once
      final freshToken = await _getValidToken();
      if (freshToken != null) {
        // Clone the request and retry with fresh token
        final newRequest = _cloneRequest(request);
        newRequest.headers['Authorization'] = 'Bearer $freshToken';
        _logger.info('Retrying request with refreshed idToken');
        return await _inner.send(newRequest);
      }
    }

    return response;
  }

  Future<String?> _getValidToken() async {
    try {
      // Return cached token if still valid (with 5-minute buffer)
      if (_cachedToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(
            _tokenExpiry!.subtract(Duration(minutes: 5)),
          )) {
        return _cachedToken;
      }

      // Fetch fresh credentials (this will auto-refresh if needed)
      final credentials = await auth0.credentialsManager.credentials(
        minTtl: 300,
      );

      // Use idToken as required by your backend
      _cachedToken = credentials.idToken;

      // Parse JWT to get actual expiry time
      _tokenExpiry =
          _parseJwtExpiry(credentials.idToken) ??
          DateTime.now().add(Duration(hours: 1)); // Fallback

      return _cachedToken;
    } catch (e) {
      _logger.severe('Failed to get valid idToken: $e');
      _cachedToken = null;
      _tokenExpiry = null;
      return null;
    }
  }

  // Parse JWT expiry from idToken
  DateTime? _parseJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.warning('Invalid JWT format');
        return null;
      }

      // Decode payload (add padding if needed)
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> claims = json.decode(decoded);

      if (claims['exp'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          claims['exp'] * 1000,
        );
        return expiry;
      }
    } catch (e) {
      _logger.warning('Failed to parse JWT expiry: $e');
    }
    return null;
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

  void clearToken() {
    _cachedToken = null;
    _tokenExpiry = null;
    _logger.info('Token cache cleared');
  }
}
