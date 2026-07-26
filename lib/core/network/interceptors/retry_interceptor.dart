import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';

/// Interceptor that retries failed requests.
///
/// This interceptor handles:
/// - 401 errors with token refresh (if user has valid credentials)
/// - Network errors with exponential backoff
class RetryInterceptor extends Interceptor {
  RetryInterceptor(
    this._logger,
    this._authService, [
    this.onAuthExpired,
  ]);

  final AppLogger _logger;
  final AuthService _authService;

  /// Callback invoked when token refresh fails and user needs to re-authenticate.
  /// This can be used to trigger logout or redirect to login screen.
  final VoidCallback? onAuthExpired;

  /// Dio instance used for retries — configured with parent's BaseOptions
  /// but without interceptors to avoid infinite loops.
  late Dio _retryDio;

  /// Maximum number of retries for network errors
  static const maxRetries = 3;

  /// Base delay for exponential backoff
  static const baseDelay = Duration(milliseconds: 1000);

  /// Currently refreshing token flag
  bool _isRefreshing = false;

  /// Requests waiting for token refresh
  final List<_RetryRequest> _refreshQueue = [];

  /// Configure the retry Dio instance with the parent Dio's options.
  /// Must be called after the parent Dio is created and interceptors are added.
  void configure(Dio parentDio) {
    _retryDio = Dio(parentDio.options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 - try to refresh token
    if (_isAuthFailure(err)) {
      // Check if user has valid credentials (refresh token available via CredentialsManager)
      final hasValidCreds = await _authService.hasValidCredentials();
      if (hasValidCreds) {
        // Queue every 401'd request — including the one that triggers the
        // refresh. Each request lives in exactly one place (the queue) and is
        // removed before its handler is called, so a handler can never be
        // completed twice.
        _refreshQueue.add(_RetryRequest(err, handler));

        // A refresh is already running; this request will be drained when it
        // completes.
        if (_isRefreshing) {
          _logger.debug('Adding request to refresh queue');
          return;
        }

        // Start token refresh.
        _isRefreshing = true;

        String? newAccessToken;
        var permanentlyLost = false;
        try {
          _logger.info('Attempting to refresh token');
          newAccessToken = await _authService.forceRefreshAccessToken();
        } catch (e) {
          // Force re-authentication when the session is permanently gone (no
          // credentials / no refresh token / opaque token) OR the renewal was
          // rejected. We only reach here *after* the server answered our
          // request with a 401, so we are provably online: a `RENEW_FAILED`
          // here is a rejected refresh token, not an offline blip, and must end
          // the session instead of looping 401s forever. (The app-open restore
          // path stays tolerant of transient renewal failures.)
          permanentlyLost = AuthService.isSessionPermanentlyLost(e) ||
              AuthService.isTokenRenewalFailed(e);
          if (permanentlyLost) {
            _logger.warning('Token refresh failed permanently - re-authentication required');
          } else {
            _logger.warning('Token refresh failed transiently - keeping session: $e');
          }
        }

        try {
          if (newAccessToken != null) {
            _logger.info(
              'Token refreshed successfully, replaying '
              '${_refreshQueue.length} queued request(s)',
            );
            await _replayQueue(newAccessToken);
          } else {
            if (permanentlyLost) onAuthExpired?.call();
            _failQueue();
          }
        } finally {
          // No `await` between the drain loop seeing an empty queue and this
          // line, so no request can be stranded.
          _isRefreshing = false;
        }
        return;
      }

      // No recoverable credentials: nothing stored, storage unreadable, or
      // the access token expired with no refresh token to renew it. Refresh
      // is impossible, so without ending the session here the user stays
      // "signed in" and every protected call 401s forever with no re-login
      // prompt. Guests are skipped — they legitimately have no credentials
      // and must not be bounced out of guest mode.
      final isGuest = await _authService.isGuestMode();
      if (!isGuest) {
        _logger.warning(
          '401 with no recoverable credentials — session is unrecoverable, '
          'forcing re-authentication',
        );
        onAuthExpired?.call();
      }
    }

    // Retry network errors with exponential backoff
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retry_count'] as int? ?? 0;
      if (retryCount < maxRetries) {
        // Use bitwise left shift for 2^retryCount (^ is XOR in Dart, not power)
        final delay = baseDelay * (1 << retryCount);
        _logger.info(
          'Retrying request (${retryCount + 1}/$maxRetries) '
          'after ${delay.inMilliseconds}ms',
        );

        await Future.delayed(delay);

        // Update retry count
        err.requestOptions.extra['retry_count'] = retryCount + 1;

        try {
          // Clone and retry the request
          final response = await _retryDio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } on DioException catch (e) {
          // If retry also fails, let it continue through error handling
          handler.next(e);
          return;
        }
      }
    }

    handler.next(err);
  }

  /// Whether [err] means the request failed *authentication* (fixable by a
  /// token refresh), per RFC 6750 that is a 401. One backend quirk widens it:
  /// FastAPI's HTTPBearer answers a request with a *missing* Authorization
  /// header with 403, not 401 — which happens when the proactive token fetch
  /// failed and [AuthInterceptor] sent the request bare. Such a 403 cannot be
  /// a real permissions error (no identity was presented), so treat it as an
  /// auth failure too. A 403 on a request that DID carry a bearer stays a
  /// genuine authorization error — refreshing would loop pointlessly.
  bool _isAuthFailure(DioException err) {
    final status = err.response?.statusCode;
    if (status == 401) return true;
    return status == 403 &&
        !err.requestOptions.headers.containsKey('Authorization');
  }

  /// A [FormData] body's underlying file streams are consumed on the first
  /// send, so replaying the same instance after a refresh would fail (multipart
  /// avatar upload). Clone it so the replay has fresh, unread streams.
  void _cloneFormDataIfNeeded(RequestOptions opts) {
    if (opts.data is FormData) {
      opts.data = (opts.data as FormData).clone();
    }
  }

  /// Check if error should be retried
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// Replay every queued request with the refreshed [accessToken].
  ///
  /// Drains via [List.removeAt] (not a `for-in` iterator) so requests that get
  /// queued while we `await` a replay are picked up in the same drain instead
  /// of throwing a concurrent-modification error. Every handler is completed
  /// exactly once.
  Future<void> _replayQueue(String accessToken) async {
    while (_refreshQueue.isNotEmpty) {
      final request = _refreshQueue.removeAt(0);
      final opts = request.error.requestOptions;
      opts.headers['Authorization'] = 'Bearer $accessToken';
      _cloneFormDataIfNeeded(opts);
      try {
        final response = await _retryDio.fetch(opts);
        request.handler.resolve(response);
      } on DioException catch (e) {
        request.handler.next(e);
      } catch (_) {
        // A non-Dio failure while replaying must still complete the handler
        // exactly once — surface the original 401 error.
        request.handler.next(request.error);
      }
    }
  }

  /// Complete every queued request with its own original error (refresh failed
  /// or was not possible). Drains via [List.removeAt] for the same
  /// concurrent-safety reason as [_replayQueue].
  void _failQueue() {
    while (_refreshQueue.isNotEmpty) {
      final request = _refreshQueue.removeAt(0);
      request.handler.next(request.error);
    }
  }
}

class _RetryRequest {
  _RetryRequest(this.error, this.handler);

  final DioException error;
  final ErrorInterceptorHandler handler;
}
