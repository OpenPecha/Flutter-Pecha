import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/localization/data/languages_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal Dio adapter that returns a canned [ResponseBody] for `/languages`.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _onFetch(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Object data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

LanguagesRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return LanguagesRemoteDatasource(dio: dio);
}

Map<String, dynamic> _langJson({
  required String code,
  String name = '',
  String nativeName = '',
  bool? enabled,
}) {
  return {
    'code': code,
    'name': name.isNotEmpty ? name : code,
    'native_name': nativeName.isNotEmpty ? nativeName : code,
    if (enabled != null) 'enabled': enabled,
  };
}

void main() {
  group('LanguagesRemoteDatasource.fetchLanguages', () {
    test('parses wrapped { languages: [...] } responses', () async {
      final ds = _datasource(
        (_) async => _jsonBody({
          'languages': [
            _langJson(code: 'en', name: 'English', nativeName: 'English'),
            _langJson(code: 'bo', name: 'Tibetan', nativeName: 'བོད་ཡིག'),
          ],
        }),
      );

      final languages = await ds.fetchLanguages();

      expect(languages.map((l) => l.code), ['en', 'bo']);
      expect(languages[1].nativeName, 'བོད་ཡིག');
    });

    test('parses bare-array responses', () async {
      final ds = _datasource(
        (_) async => _jsonBody([
          _langJson(code: 'zh', name: 'Chinese', nativeName: '中文'),
          _langJson(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
        ]),
      );

      final languages = await ds.fetchLanguages();

      expect(languages.map((l) => l.code), ['zh', 'hi']);
    });

    test('filters disabled languages and empty codes', () async {
      final ds = _datasource(
        (_) async => _jsonBody({
          'languages': [
            _langJson(code: 'en', enabled: true),
            _langJson(code: 'bo', enabled: false),
            _langJson(code: '', name: 'Empty'),
            _langJson(code: '  ', name: 'Whitespace'),
            _langJson(code: 'zh'), // enabled omitted → defaults true
          ],
        }),
      );

      final languages = await ds.fetchLanguages();

      expect(languages.map((l) => l.code), ['en', 'zh']);
    });

    test('throws ServerException on non-200 responses', () async {
      final ds = _datasource((_) async => _jsonBody({}, statusCode: 500));

      await expectLater(
        ds.fetchLanguages(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

    test('maps connection timeout DioException to NetworkException', () async {
      final ds = _datasource(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/languages'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      await expectLater(
        ds.fetchLanguages(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            'Connection timeout',
          ),
        ),
      );
    });

    test('maps connectionError DioException to NetworkException', () async {
      final ds = _datasource(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/languages'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        ds.fetchLanguages(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            'No internet connection',
          ),
        ),
      );
    });

    test('maps DioException with response status to ServerException', () async {
      final ds = _datasource(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/languages'),
          response: Response(
            requestOptions: RequestOptions(path: '/languages'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        ds.fetchLanguages(),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('503'),
          ),
        ),
      );
    });

    test('maps other DioException types to NetworkException', () async {
      final ds = _datasource(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/languages'),
          type: DioExceptionType.cancel,
        ),
      );

      await expectLater(
        ds.fetchLanguages(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            'Network error',
          ),
        ),
      );
    });
  });

  group('LanguagesRemoteDatasource.updateLanguage', () {
    test('PUTs uppercase language code', () async {
      RequestOptions? captured;
      final ds = _datasource((options) async {
        captured = options;
        return _jsonBody({});
      });

      await ds.updateLanguage('bo');

      expect(captured?.method, 'PUT');
      expect(captured?.path, '/users/me/language');
      expect(captured?.data, {'language': 'BO'});
    });

    test('skips empty language code', () async {
      var called = false;
      final ds = _datasource((options) async {
        called = true;
        return _jsonBody({});
      });

      await ds.updateLanguage('   ');

      expect(called, isFalse);
    });

    test('maps connection errors to NetworkException', () async {
      final ds = _datasource(
        (_) async => throw DioException(
          requestOptions: RequestOptions(path: '/users/me/language'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        ds.updateLanguage('en'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
