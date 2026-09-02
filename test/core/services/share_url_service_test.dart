import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_remote_datasource.dart';
import 'package:flutter_pecha/core/services/share_url/share_url_service.dart';
import 'package:flutter_test/flutter_test.dart';

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

ShareUrlRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.webuddhist.com'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return ShareUrlRemoteDatasource(dio: dio);
}

void main() {
  group('ShareUrlRemoteDatasource', () {
    test('posts the long url and returns shortUrl', () async {
      const longUrl =
          'https://webuddhist.com/open/group-accumulator/abc?group=def';
      final datasource = _datasource((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/share');
        expect(options.data, {'url': longUrl});
        return _jsonBody({'shortUrl': 'https://wb.pub/bodho'});
      });

      final result = await datasource.shortenUrl(longUrl);

      expect(result, 'https://wb.pub/bodho');
    });

    test('throws when shortUrl is missing', () async {
      final datasource = _datasource((_) async => _jsonBody({}));

      expect(
        () => datasource.shortenUrl('https://webuddhist.com/open'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('ShareUrlService', () {
    test('returns original url when shortening fails', () async {
      const longUrl = 'https://webuddhist.com/open/plan/plan-1';
      final service = ShareUrlService(
        remoteDatasource: _datasource(
          (_) async => _jsonBody({}, statusCode: 500),
        ),
      );

      final result = await service.shorten(longUrl);

      expect(result, longUrl);
    });

    test('returns trimmed short url on success', () async {
      const longUrl = 'https://webuddhist.com/open/poem/poem-1';
      final service = ShareUrlService(
        remoteDatasource: _datasource(
          (_) async => _jsonBody({'shortUrl': 'https://wb.pub/poem1'}),
        ),
      );

      final result = await service.shorten('  $longUrl  ');

      expect(result, 'https://wb.pub/poem1');
    });
  });
}
