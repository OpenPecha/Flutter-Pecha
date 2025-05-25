import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/texts.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:http/http.dart' as http;

class TextRemoteDatasource {
  final http.Client client;

  TextRemoteDatasource({required this.client});

  // to get the texts
  Future<List<Texts>> fetchTexts({
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
      final List<dynamic> textsJson = jsonMap['texts'] ?? [];
      return textsJson
          .map((json) => Texts.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load texts');
    }
  }

  // get the content of the text
  Future<List<Section>> fetchTextContent({
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
      final sectionData = jsonMap["contents"][0]['sections'] as List<dynamic>;
      return sectionData
          .map((json) => Section.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load text content');
    }
  }

  // get the version of the text
  Future<List<Version>> fetchTextVersion({
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
      final versionData = jsonMap['versions'] as List<dynamic>;
      return versionData
          .map((json) => Version.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load text version');
    }
  }
}
