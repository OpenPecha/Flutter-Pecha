import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/network/interceptors/error_interceptor.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_chat/chat_moderation.dart';
import 'package:flutter_test/flutter_test.dart';

class _CaptureHandler extends Fake implements ErrorInterceptorHandler {
  DioException? captured;

  @override
  void next(DioException err) {
    captured = err;
  }
}

void main() {
  test('ErrorInterceptor keeps code from 400 JSON body', () {
    final interceptor = ErrorInterceptor(AppLogger('ErrorInterceptorTest'));
    final options = RequestOptions(path: '/chat/groups/g1/messages');
    final err = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: 400,
        data: {
          'success': false,
          'code': ChatModeration.inappropriateLanguage,
          'message': 'blocked',
        },
      ),
    );
    final handler = _CaptureHandler();
    interceptor.onError(err, handler);
    expect(handler.captured?.error, isA<ValidationException>());
    final exception = handler.captured!.error! as ValidationException;
    expect(exception.code, ChatModeration.inappropriateLanguage);
    expect(exception.message, 'blocked');
  });
}
