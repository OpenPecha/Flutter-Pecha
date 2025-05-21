import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/texts.dart';
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
}
