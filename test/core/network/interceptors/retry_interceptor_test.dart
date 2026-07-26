import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/network/interceptors/retry_interceptor.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'retry_interceptor_test.mocks.dart';

@GenerateMocks([AuthService, ErrorInterceptorHandler])
void main() {
  late MockAuthService authService;
  late MockErrorInterceptorHandler handler;
  late int authExpiredCalls;
  late RetryInterceptor interceptor;

  DioException authError({int statusCode = 401, String? bearer}) {
    final options = RequestOptions(
      path: '/users/me/plans',
      headers: {if (bearer != null) 'Authorization': 'Bearer $bearer'},
    );
    return DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: statusCode),
      type: DioExceptionType.badResponse,
    );
  }

  DioException unauthorized() => authError();

  setUp(() {
    authService = MockAuthService();
    handler = MockErrorInterceptorHandler();
    authExpiredCalls = 0;
    interceptor = RetryInterceptor(
      AppLogger('RetryInterceptorTest'),
      authService,
      () => authExpiredCalls++,
    );
  });

  group('401 with no recoverable credentials', () {
    test('ends the session for a signed-in user', () async {
      when(authService.hasValidCredentials()).thenAnswer((_) async => false);
      when(authService.isGuestMode()).thenAnswer((_) async => false);

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 1);
      verify(handler.next(err)).called(1);
      verifyNever(handler.resolve(any));
    });

    test('does not end the session for a guest', () async {
      when(authService.hasValidCredentials()).thenAnswer((_) async => false);
      when(authService.isGuestMode()).thenAnswer((_) async => true);

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 0);
      verify(handler.next(err)).called(1);
    });
  });

  group('403 handling', () {
    test(
      'treats a 403 on a request sent WITHOUT a bearer as an auth failure '
      '(FastAPI missing-header quirk)',
      () async {
        when(authService.hasValidCredentials()).thenAnswer((_) async => false);
        when(authService.isGuestMode()).thenAnswer((_) async => false);

        final err = authError(statusCode: 403);
        interceptor.onError(err, handler);
        await untilCalled(handler.next(any));

        expect(authExpiredCalls, 1);
        verify(handler.next(err)).called(1);
      },
    );

    test(
      'leaves a 403 on a request that DID carry a bearer as a genuine '
      'permissions error — no refresh, no logout',
      () async {
        final err = authError(statusCode: 403, bearer: 'some.valid.jwt');
        interceptor.onError(err, handler);
        await untilCalled(handler.next(any));

        expect(authExpiredCalls, 0);
        verify(handler.next(err)).called(1);
        verifyNever(authService.hasValidCredentials());
        verifyNever(authService.forceRefreshAccessToken());
      },
    );
  });

  group('401 with credentials but a permanently failed refresh', () {
    test('ends the session and fails the queued request', () async {
      when(authService.hasValidCredentials()).thenAnswer((_) async => true);
      when(authService.forceRefreshAccessToken()).thenThrow(
        AuthException(
          'Opaque access token; re-authentication required',
          code: AuthService.opaqueAccessTokenCode,
        ),
      );

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 1);
      verify(handler.next(err)).called(1);
      verifyNever(handler.resolve(any));
    });

    test('keeps the session on a transient refresh failure', () async {
      when(authService.hasValidCredentials()).thenAnswer((_) async => true);
      when(authService.forceRefreshAccessToken())
          .thenThrow(AuthException('offline'));

      final err = unauthorized();
      interceptor.onError(err, handler);
      await untilCalled(handler.next(any));

      expect(authExpiredCalls, 0);
      verify(handler.next(err)).called(1);
    });
  });
}
