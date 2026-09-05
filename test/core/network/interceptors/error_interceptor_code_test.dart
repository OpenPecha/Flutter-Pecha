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


DioException _badResponse(int statusCode, Object? data) {
  final options = RequestOptions(path: '/chat/groups/g1/messages');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

Object? _capture(DioException err) {
  final handler = _CaptureHandler();
  ErrorInterceptor(AppLogger('ErrorInterceptorTest')).onError(err, handler);
  return handler.captured?.error;
}

void _detailEnvelope() {
  group('FastAPI detail envelope', () {
    test('a code inside detail is kept', () {
      // HTTPException(status_code=400, detail={...}) is the shape the backend
      // raises. Reading only the top level left code null, so the profanity
      // and invalid-parent branches downstream could never match.
      final error =
          _capture(_badResponse(400, {
                'detail': {
                  'code': ChatModeration.inappropriateLanguage,
                  'message': 'blocked',
                },
              }))
              as ValidationException;

      expect(error.code, ChatModeration.inappropriateLanguage);
      expect(error.message, 'blocked');
    });

    test('a plain string detail becomes the message', () {
      final error =
          _capture(_badResponse(400, {'detail': 'Body must not be empty'}))
              as ValidationException;

      expect(error.message, 'Body must not be empty');
    });

    test('a 404 keeps the reason the server gave', () {
      final error =
          _capture(_badResponse(404, {'detail': 'Message not found'}))
              as NotFoundException;

      expect(error.message, 'Message not found');
    });

    test('a 404 with no detail keeps the generic wording', () {
      final error = _capture(_badResponse(404, null)) as NotFoundException;

      expect(error.message, 'Resource not found');
    });
  });
}

void main() {
  _detailEnvelope();
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
