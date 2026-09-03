import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';

/// Centralized mapper from Exceptions to Failures.
///
/// This is the single place in the repository layer that converts
/// exceptions to failures. Used by all repositories.
class ExceptionMapper {
  ExceptionMapper._();

  /// Map any exception to its corresponding Failure type.
  ///
  /// [exception] - The exception to map
  /// [context] - Optional context prefix for failure messages
  static Failure map(Object exception, {String? context}) {
    if (exception is DioException && exception.error != null) {
      return map(exception.error!, context: context);
    }

    final prefix = context != null ? '$context: ' : '';
    final error = _unwrap(exception);

    return switch (error) {
      AuthenticationException e => AuthenticationFailure('$prefix${e.message}'),
      AuthorizationException e => AuthorizationFailure('$prefix${e.message}'),
      NotFoundException e => NotFoundFailure('$prefix${e.message}'),
      NetworkException e => NetworkFailure('$prefix${e.message}'),
      ServerException e => ServerFailure('$prefix${e.message}'),
      ValidationException e => ValidationFailure(
        '$prefix${e.message}',
        code: e.code,
      ),
      RateLimitException e => RateLimitFailure('$prefix${e.message}'),
      CacheException e => CacheFailure('$prefix${e.message}'),
      PairingException e => PairingFailure('$prefix${e.message}'),
      _ => UnknownFailure('$prefix${error.toString()}'),
    };
  }

  /// Unwraps the [DioException] envelope that [ErrorInterceptor] re-wraps its
  /// typed [AppException] in before Dio rethrows it.
  ///
  /// Datasources that call Dio without their own `catch` hand the repository a
  /// [DioException] whose `error` holds the real typed exception. Matching on
  /// the envelope would send every HTTP failure — 401 and 500 alike — down the
  /// `UnknownFailure` branch and leak `DioException [bad response]: …` into
  /// user-facing text, so unwrap first and map the typed cause.
  static Object _unwrap(Object exception) =>
      exception is DioException ? (exception.error ?? exception) : exception;
}
