import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/features/poems/data/datasource/poems_remote_datasource.dart';
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

PoemsRemoteDatasource _datasource(
  Future<ResponseBody> Function(RequestOptions) onFetch,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.httpClientAdapter = _FakeAdapter(onFetch);
  return PoemsRemoteDatasource(dio: dio);
}

Map<String, dynamic> _poemJson(String id) => {
  'id': id,
  'title': 'Title $id',
  'content': 'Content',
  'author_name': 'Author',
};

void main() {
  group('PoemsRemoteDatasource.fetchPoems pagination', () {
    test('uses skip plus page length when total is in the response', () async {
      final pageOne = List.generate(20, (i) => _poemJson('p$i'));
      final pageTwo = List.generate(5, (i) => _poemJson('p${i + 20}'));
      var calls = 0;

      final ds = _datasource((_) async {
        calls++;
        if (calls == 1) {
          return _jsonBody({'poems': pageOne, 'total': 25});
        }
        if (calls == 2) {
          return _jsonBody({'poems': pageTwo, 'total': 25});
        }
        return _jsonBody({'poems': [], 'total': 25});
      });

      final first = await ds.fetchPoems(language: 'bo', skip: 0, limit: 20);
      expect(first.poems.length, 20);
      expect(first.hasMore, isTrue);

      final second = await ds.fetchPoems(language: 'bo', skip: 20, limit: 20);
      expect(second.poems.length, 5);
      expect(second.hasMore, isFalse);

      final beyond = await ds.fetchPoems(language: 'bo', skip: 25, limit: 20);
      expect(beyond.poems, isEmpty);
      expect(beyond.hasMore, isFalse);
    });

    test('falls back to page-size heuristic when total is absent', () async {
      final ds = _datasource(
        (_) async => _jsonBody(List.generate(20, (i) => _poemJson('p$i'))),
      );

      final fullPage = await ds.fetchPoems(language: 'bo', skip: 0, limit: 20);
      expect(fullPage.hasMore, isTrue);

      final shortPage = _datasource(
        (_) async => _jsonBody(List.generate(3, (i) => _poemJson('p$i'))),
      );
      final partial = await shortPage.fetchPoems(
        language: 'bo',
        skip: 40,
        limit: 20,
      );
      expect(partial.hasMore, isFalse);
    });
  });
}
