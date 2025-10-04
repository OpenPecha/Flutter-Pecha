// lib/core/network/authenticated_http_client.dart
import 'dart:async';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:http/http.dart' as http;

class AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final AuthService authService;

  AuthenticatedHttpClient._internal(this._inner, this.authService);

  static AuthenticatedHttpClient? _instance;

  factory AuthenticatedHttpClient(http.Client inner, AuthService authService) {
    _instance ??= AuthenticatedHttpClient._internal(inner, authService);
    return _instance!;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add auth header for protected endpoints
    if (_needsAuthentication(request.url.path)) {
      final token = await authService.getValidIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    final response = await _inner.send(request);

    return response;
  }

  bool _needsAuthentication(String path) {
    // Define which endpoints need authentication
    final protectedPaths = ['/api/v1/users/me', '/api/v1/users/me/plans'];

    return protectedPaths.any(
      (protectedPath) => path.startsWith(protectedPath.replaceAll('/*', '')),
    );
  }
}
