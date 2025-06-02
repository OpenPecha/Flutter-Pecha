import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
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
      final contents = jsonMap["contents"] as List<dynamic>;
      if (contents.isEmpty) {
        return [];
      }
      final contentId = contents[0]['id'] as String;
      final sectionData = contents[0]['sections'] as List<dynamic>;
      // update all the sections with contentId as "content_id"
      for (var section in sectionData) {
        section['content_id'] = contentId;
      }
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
      if (versionData.isEmpty) {
        return [];
      }
      return versionData
          .map((json) => Version.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load text version');
    }
  }

  // post request to get the details of the text
  Future<Map<String, dynamic>> fetchTextDetails({
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
        final decoded = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonMap = json.decode(decoded);
        final sections = jsonMap["content"]["sections"] as List<dynamic>;
        if (sections.isEmpty) {
          return {};
        }
        final sectionsList =
            sections
                .map((e) => Section.fromJson(e as Map<String, dynamic>))
                .toList();
        // final segments = sections[0]["segments"] as List<dynamic>;
        // final segmentsList =
        //     segments
        //         .map((e) => Segment.fromJson(e as Map<String, dynamic>))
        //         .toList();
        final textDetail = TextDetail.fromJson(
          jsonMap["text_detail"] as Map<String, dynamic>,
        );
        return {"textDetail": textDetail, "sectionsList": sectionsList};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }
}
