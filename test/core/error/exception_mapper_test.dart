import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rebuilds what `ErrorInterceptor` hands the repository layer: the typed
/// [AppException] re-wrapped inside a fresh [DioException].
DioException _wrapped(Exception typed, {int? statusCode}) {
  final options = RequestOptions(path: '/users/me/bookmarks');
  return DioException(
    requestOptions: options,
    response: statusCode == null
        ? null
        : Response<dynamic>(requestOptions: options, statusCode: statusCode),
    type: DioExceptionType.badResponse,
    error: typed,
    message: typed.toString(),
  );
}

void main() {
  group('ExceptionMapper.map unwraps the DioException envelope', () {
    test('a wrapped ServerException maps to ServerFailure, not UnknownFailure',
        () {
      final failure = ExceptionMapper.map(
        _wrapped(const ServerException('Server error (500)'), statusCode: 500),
        context: 'Failed to load bookmarks',
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Failed to load bookmarks: Server error (500)');
    });

    test('the raw DioException string never reaches the failure message', () {
      final failure = ExceptionMapper.map(
        _wrapped(const ServerException('Server error (500)'), statusCode: 500),
        context: 'Failed to load bookmarks',
      );

      expect(failure.message, isNot(contains('DioException')));
      expect(failure.message, isNot(contains('bad response')));
    });

    test('a wrapped AuthenticationException maps to AuthenticationFailure', () {
      final failure = ExceptionMapper.map(
        _wrapped(const AuthenticationException('Unauthorized'), statusCode: 401),
      );

      expect(failure, isA<AuthenticationFailure>());
      expect(failure.message, 'Unauthorized');
    });

    test('a wrapped NetworkException maps to NetworkFailure', () {
      final failure = ExceptionMapper.map(
        _wrapped(const NetworkException('No internet connection')),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('a wrapped ValidationException preserves its code', () {
      final failure = ExceptionMapper.map(
        _wrapped(const ValidationException('Bad input', code: 'INVALID')),
      );

      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'INVALID');
    });

    test('a DioException carrying no typed cause still maps to a failure', () {
      final failure = ExceptionMapper.map(
        DioException(
          requestOptions: RequestOptions(path: '/users/me/bookmarks'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(failure, isA<UnknownFailure>());
    });

    test('an unwrapped typed exception is mapped as before', () {
      final failure = ExceptionMapper.map(
        const NotFoundException('Resource not found'),
        context: 'ctx',
      );

      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'ctx: Resource not found');
    });
  });
}
