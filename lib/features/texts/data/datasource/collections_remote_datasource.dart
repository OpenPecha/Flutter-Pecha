import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections_response.dart';
import 'package:http/http.dart' as http;

class CollectionsRemoteDatasource {
  final http.Client client;

  CollectionsRemoteDatasource({required this.client});

  Future<CollectionsResponse> fetchCollections({
    String? parentId,
    String? language,
    int skip = 0,
    int limit = 50,
  }) async {
    final uri = Uri.parse('${dotenv.env['BASE_API_URL']}/collections').replace(
      queryParameters: {
        if (parentId != null) 'parent_id': parentId,
        if (language != null) 'language': language,
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await client.get(uri);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonMap = json.decode(decoded);
      return CollectionsResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load collections');
    }
  }
}
