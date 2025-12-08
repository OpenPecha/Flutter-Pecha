import 'dart:async';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiClient extends http.BaseClient {
  final AuthService _authService;
  final http.Client _inner = http.Client();
  static const List<String> _protectedPaths = [
    // user profile
    '/api/v1/users/info',
    '/api/v1/users/upload',

    // public plans
    '/api/v1/plans/{planId}/days',
    '/api/v1/plans/{planId}/days/{dayNumber}',

    // user progress
    '/api/v1/users/me',
    '/api/v1/users/me/plans',
    '/api/v1/users/me/plans/{planId}',
    '/api/v1/users/me/tasks',
    '/api/v1/users/me/tasks/{taskId}/complete',
    '/api/v1/users/me/sub-tasks',
    '/api/v1/users/me/sub-tasks/{subTaskId}/complete',
    '/api/v1/users/me/task/{taskId}',
    '/api/v1/users/me/plan/{planId}/days/{dayNumber}',

    // recitations
    '/api/v1/users/me/recitations',
    // Add more as needed
  ];
  final _logger = AppLogger('ApiClient');

  ApiClient(this._authService);

  @override
  void close() {
    _logger.debug('Closing ApiClient HTTP client');
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
        _logger.debug(
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
          _logger.debug('${retryResponse.statusCode} ${request.url}');
          return retryResponse;
        }
      } catch (e) {
        _logger.error('Error in ApiClient', e);
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
      (protectedPath) => _matchesPathPattern(path, protectedPath),
    );
  }

  /// Matches a path against a pattern that may contain path parameters like {planId}
  bool _matchesPathPattern(String path, String pattern) {
    // If no parameters in pattern, do simple prefix match
    if (!pattern.contains('{')) {
      return path.startsWith(pattern);
    }

    // Split both path and pattern into segments
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
    final patternSegments =
        pattern.split('/').where((s) => s.isNotEmpty).toList();

    // Must have same number of segments
    if (pathSegments.length != patternSegments.length) {
      return false;
    }

    // Compare each segment
    for (var i = 0; i < pathSegments.length; i++) {
      final pathSegment = pathSegments[i];
      final patternSegment = patternSegments[i];

      // If pattern segment is a parameter (e.g., {planId}), it matches any value
      if (patternSegment.startsWith('{') && patternSegment.endsWith('}')) {
        continue;
      }

      // Otherwise, segments must match exactly
      if (pathSegment != patternSegment) {
        return false;
      }
    }

    return true;
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
