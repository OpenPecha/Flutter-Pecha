import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Interceptor that converts HTTP errors to domain exceptions.
///
/// Centralizes error handling for all HTTP requests, converting
/// DioExceptions into typed domain exceptions.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = err.requestOptions.extra['requestId'] ?? 'unknown';
    final exception = _convertDioException(err);

    // Log the error with request ID for correlation
    _logger.error(
      '[$requestId] API Error: ${err.message}',
      exception,
      err.stackTrace,
    );

    // Create a new DioException with our custom exception
    final error = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: exception,
      message: exception.toString(),
    );

    handler.next(error);
  }

  /// Convert DioException to domain exception
  Exception _convertDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Connection timeout');

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return const NetworkException('Request cancelled');

      case DioExceptionType.connectionError:
        return const NetworkException('No internet connection');

      case DioExceptionType.unknown:
        // Check for specific error messages
        final message = error.message?.toLowerCase() ?? '';
        if (message.contains('socket') ||
            message.contains('network') ||
            message.contains('connection')) {
          return const NetworkException('Network error');
        }
        return NetworkException('Unknown error: ${error.message}');

      case DioExceptionType.badCertificate:
        return const NetworkException('Invalid SSL certificate');
    }
  }

  /// Handle HTTP error responses
  Exception _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final body = responseData is Map<String, dynamic> ? responseData : null;
    final message = body?['message'] as String? ?? 'Server error';
    final code = body?['code'] as String?;

    switch (statusCode) {
      case 400:
        return ValidationException(message, code: code);
      case 401:
        return const AuthenticationException('Unauthorized');
      case 403:
        return const AuthorizationException('Forbidden');
      case 404:
        return const NotFoundException('Resource not found');
      case 409:
        return ValidationException(message, code: code);
      case 429:
        return const RateLimitException('Too many requests');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException('Server error ($statusCode)');
      default:
        return ServerException('HTTP $statusCode: $message');
    }
  }
}
