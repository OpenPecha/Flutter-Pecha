import 'dart:async';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class ApiClient extends http.BaseClient {
  final AuthService _authService;
  final http.Client _inner = http.Client();
  static const List<String> _protectedPaths = [
    '/api/v1/users/me',
    '/api/v1/users/me/plans',
    '/api/v1/users/me/onboarding-preferences',
    // Add more as needed
  ];
  final Logger _logger = Logger('ApiClient');

  ApiClient(this._authService);

  @override
  void close() {
    _logger.fine('Closing ApiClient HTTP client');
    _inner.close();
    super.close();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _logger.info('${request.method} ${request.url}');

    // Add authentication header for protected routes
    if (_isProtectedRoute(request.url.path)) {
      final token = await _authService.getValidIdToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        _logger.fine(
          'Added auth token for ${request.method} ${request.url.path}',
        );
      } else {
        _logger.warning('No ID token available for protected route');
      }
    }

    // Set content type if not already set
    if (!request.headers.containsKey('Content-Type')) {
      request.headers['Content-Type'] = 'application/json';
    }

    final response = await _inner.send(request);

    // Handle 401 by refreshing token and retrying once
    if (response.statusCode == 401 && _isProtectedRoute(request.url.path)) {
      try {
        _logger.info('Received 401, attempting to forcing token refresh');

        // Clone the original request for retry
        final newRequest = _cloneRequest(request);

        // FORCE refresh (not just getValid, which might return same expired token)
        final newToken = await _authService.refreshIdToken();
        if (newToken != null) {
          // Add the new token to the cloned request
          newRequest.headers['Authorization'] = 'Bearer $newToken';
          _logger.info('Retrying request with refreshed token');
          final retryResponse = await _inner.send(newRequest);
          _logger.fine('${retryResponse.statusCode} ${request.url}');
          return retryResponse;
        }
      } catch (e) {
        _logger.warning('Token refresh returned null, returning original 401');
      }
    }
    _logger.info('${response.statusCode} ${request.url}');
    return response;
  }

  // Helper method to clone a request
  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    http.BaseRequest newRequest;

    if (request is http.Request) {
      newRequest =
          http.Request(request.method, request.url)
            ..encoding = request.encoding
            ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      newRequest =
          http.MultipartRequest(request.method, request.url)
            ..fields.addAll(request.fields)
            ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('Cannot retry streamed requests');
    } else {
      throw Exception('Unknown request type');
    }

    newRequest.headers.addAll(request.headers);
    return newRequest;
  }

  bool _isProtectedRoute(String path) {
    return _protectedPaths.any(
      (protectedPath) => path.startsWith(protectedPath),
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  final client = ApiClient(authService);

  ref.onDispose(() {
    client.close();
  });
  return client;
});
