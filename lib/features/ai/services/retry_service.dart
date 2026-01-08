import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';

/// Service for retrying failed operations with exponential backoff
class RetryService {
  RetryService._();

  static final _logger = AppLogger('RetryService');

  static const int maxRetries = 3;

  static const Duration baseDelay = Duration(seconds: 1);

  static const Duration maxDelay = Duration(seconds: 10);

  /// Jitter factor to add randomness (0.0 to 1.0)
  static const double jitterFactor = 0.1;

  /// Executes an operation with exponential backoff retry logic
  ///
  /// [operation] - The async operation to execute
  /// [shouldRetry] - Optional custom function to determine if retry should occur
  /// [onRetry] - Optional callback when a retry occurs
  ///
  /// Returns the result of the operation if successful
  /// Throws the last exception if all retries are exhausted
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(Exception)? shouldRetry,
    void Function(int attempt, Duration delay, Exception error)? onRetry,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;

        // Check if this is the last attempt
        if (attempt >= maxRetries) {
          _logger.error('Max retries ($maxRetries) exceeded');
          break;
        }

        // Check if we should retry this exception
        final shouldRetryException = shouldRetry?.call(e) ?? _isRetryable(e);
        if (!shouldRetryException) {
          _logger.debug('Exception is not retryable: ${e.runtimeType}');
          break;
        }

        // Calculate delay with exponential backoff and jitter
        final delay = _getBackoffDelay(attempt);
        _logger.warning(
          'Attempt ${attempt + 1} failed, retrying in ${delay.inMilliseconds}ms: $e',
        );

        // Notify callback if provided
        onRetry?.call(attempt + 1, delay, e);

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    // All retries exhausted, throw the last exception
    throw lastException ?? Exception('Unknown error during retry');
  }

  /// Determines if an exception is retryable
  ///
  /// Retryable exceptions:
  /// - NetworkException (connection issues)
  /// - ServerException (5xx server errors)
  /// - TimeoutException (request timeout)
  /// - SocketException (network socket issues)
  ///
  /// Non-retryable exceptions:
  /// - AuthenticationException (401)
  /// - AuthorizationException (403)
  /// - NotFoundException (404)
  /// - ValidationException (400)
  /// - RateLimitException (429) - should wait, not retry immediately
  static bool _isRetryable(Exception e) {
    // Retryable exceptions
    if (e is NetworkException) return true;
    if (e is ServerException) return true;
    if (e is TimeoutException) return true;
    if (e is SocketException) return true;

    // Non-retryable exceptions
    if (e is AuthenticationException) return false;
    if (e is AuthorizationException) return false;
    if (e is NotFoundException) return false;
    if (e is ValidationException) return false;
    if (e is RateLimitException) return false;
    if (e is CacheException) return false;

    // For generic exceptions, check the message for common patterns
    final message = e.toString().toLowerCase();
    if (message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504')) {
      return true;
    }

    // Default: don't retry unknown exceptions
    return false;
  }

  /// Calculates the backoff delay for a given attempt
  ///
  /// Uses exponential backoff: delay = baseDelay * 2^attempt
  /// Adds random jitter to prevent thundering herd
  /// Caps at maxDelay
  static Duration _getBackoffDelay(int attempt) {
    // Calculate exponential delay: 1s, 2s, 4s, 8s...
    final exponentialDelay = baseDelay * pow(2, attempt);

    // Cap at maximum delay
    final cappedDelay = exponentialDelay > maxDelay ? maxDelay : exponentialDelay;

    // Add jitter (random variation up to jitterFactor of the delay)
    final random = Random();
    final jitter = cappedDelay.inMilliseconds * jitterFactor * random.nextDouble();
    final delayWithJitter = cappedDelay.inMilliseconds + jitter.toInt();

    return Duration(milliseconds: delayWithJitter);
  }
}
