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
    final prefix = context != null ? '$context: ' : '';

    return switch (exception) {
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
      _ => UnknownFailure('$prefix${exception.toString()}'),
    };
  }
}
