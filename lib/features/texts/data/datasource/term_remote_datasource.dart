// lib/features/texts/data/datasources/term_remote_datasource.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/term/term_response.dart';
import 'package:http/http.dart' as http;

class TermRemoteDatasource {
  final http.Client client;

  TermRemoteDatasource({required this.client});

  Future<TermResponse> fetchTerms({
    String? parentId,
    String? language,
    int skip = 0,
    int limit = 10,
  }) async {
    final uri = Uri.parse('${dotenv.env['BASE_API_URL']}/terms').replace(
      queryParameters: {
        if (parentId != null) 'parent_id': parentId,
        if (language != null) 'language': language == 'zh' ? 'en' : language,
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonMap = json.decode(decoded);
      return TermResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load terms');
    }
  }
}
