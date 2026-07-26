import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/network/interceptors/cache_interceptor.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'cache_interceptor_test.mocks.dart';

@GenerateMocks([RequestInterceptorHandler, ResponseInterceptorHandler])
void main() {
  late CacheInterceptor interceptor;

  setUp(() {
    interceptor = CacheInterceptor(AppLogger('CacheInterceptorTest'));
  });

  RequestOptions request(String path, {bool authed = false}) {
    return RequestOptions(
      path: path,
      method: 'GET',
      headers: {if (authed) 'Authorization': 'Bearer token'},
    );
  }

  /// Store a 200 response for [options] in the cache.
  void prime(RequestOptions options, Object data) {
    final responseHandler = MockResponseInterceptorHandler();
    interceptor.onResponse(
      Response(requestOptions: options, statusCode: 200, data: data),
      responseHandler,
    );
  }

  test('an anonymous response is not served to an authenticated request',
      () async {
    prime(request('/series'), 'anonymous-body');

    final handler = MockRequestInterceptorHandler();
    interceptor.onRequest(request('/series', authed: true), handler);

    // Different auth scope → cache miss → request continues to the network.
    verify(handler.next(any)).called(1);
    verifyNever(handler.resolve(any));
  });

  test('an authenticated response is served to a matching request', () async {
    prime(request('/series', authed: true), 'authed-body');

    final handler = MockRequestInterceptorHandler();
    interceptor.onRequest(request('/series', authed: true), handler);

    final resolved =
        verify(handler.resolve(captureAny)).captured.single as Response;
    expect(resolved.data, 'authed-body');
    verifyNever(handler.next(any));
  });

  test('clearUserScoped drops authenticated entries but keeps anonymous ones',
      () async {
    prime(request('/series', authed: true), 'authed-body');
    prime(request('/languages'), 'public-body');

    interceptor.clearUserScoped();

    final authedHandler = MockRequestInterceptorHandler();
    interceptor.onRequest(request('/series', authed: true), authedHandler);
    verify(authedHandler.next(any)).called(1);

    final anonHandler = MockRequestInterceptorHandler();
    interceptor.onRequest(request('/languages'), anonHandler);
    verify(anonHandler.resolve(any)).called(1);
  });

  test('invalidate removes entries for a path across both auth scopes',
      () async {
    prime(request('/series', authed: true), 'authed-body');
    prime(request('/series'), 'anonymous-body');

    interceptor.invalidate('/series');

    final authedHandler = MockRequestInterceptorHandler();
    interceptor.onRequest(request('/series', authed: true), authedHandler);
    verify(authedHandler.next(any)).called(1);

    final anonHandler = MockRequestInterceptorHandler();
    interceptor.onRequest(request('/series'), anonHandler);
    verify(anonHandler.next(any)).called(1);
  });

  test('user-specific paths are never cached', () async {
    prime(request('/users/me/plans', authed: true), 'user-plans');

    final handler = MockRequestInterceptorHandler();
    interceptor.onRequest(request('/users/me/plans', authed: true), handler);
    verify(handler.next(any)).called(1);
    verifyNever(handler.resolve(any));
  });
}
