import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/models/text/reader_response.dart';
import 'package:flutter_pecha/features/texts/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/models/text/version_response.dart';
import 'package:http/http.dart' as http;

class TextRemoteDatasource {
  final http.Client client;

  TextRemoteDatasource({required this.client});

  // to get the texts
  Future<TextDetailResponse> fetchTexts({
    required String termId,
    String? language,
    int skip = 0,
    int limit = 10,
  }) async {
    final uri = Uri.parse('${dotenv.env['BASE_API_URL']}/texts').replace(
      queryParameters: {
        'term_id': termId,
        if (language != null) 'language': language,
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonMap = json.decode(decoded);
      return TextDetailResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load texts');
    }
  }

  // get the content of the text
  Future<TocResponse> fetchTextContent({
    required String textId,
    String? language,
  }) async {
    final uri = Uri.parse(
      '${dotenv.env['BASE_API_URL']}/texts/$textId/contents',
    ).replace(queryParameters: {'language': language ?? 'en'});

    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonMap = json.decode(decoded);
      return TocResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load text content');
    }
  }

  // get the version of the text
  Future<VersionResponse> fetchTextVersion({
    required String textId,
    String? language,
  }) async {
    final uri = Uri.parse(
      '${dotenv.env['BASE_API_URL']}/texts/$textId/versions',
    ).replace(queryParameters: {'language': language ?? 'en'});

    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonMap = json.decode(decoded);
      return VersionResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load text version');
    }
  }

  // post request to get the details of the text
  Future<ReaderResponse> fetchTextDetails({
    required String textId,
    required String contentId,
    String? versionId,
    String? skip,
  }) async {
    final uri = Uri.parse(
      '${dotenv.env['BASE_API_URL']}/texts/$textId/details',
    );
    final body = json.encode({
      'content_id': contentId,
      'version_id': versionId,
      'skip': skip ?? 0,
      'limit': 1,
    });
    try {
      final response = await client.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        try {
          final decoded = utf8.decode(response.bodyBytes);
          final Map<String, dynamic> jsonMap = json.decode(decoded);
          return ReaderResponse.fromJson(jsonMap);
        } catch (e) {
          throw Exception('Failed to load text details in response $e');
        }
      } else {
        throw Exception('Failed to load text details ::: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load text details ????? $e');
    }
  }
}
