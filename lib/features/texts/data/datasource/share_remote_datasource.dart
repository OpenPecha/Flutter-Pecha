import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;

class ShareRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;
  final _logger = AppLogger('ShareRemoteDatasource');

  ShareRemoteDatasource({required this.client});

  // POST request to share a short url
  Future<String> getShareUrl({
    required String textId,
    required String segmentId,
    required String language,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/share');
      final body = json.encode({
        'logo': false,
        'segment_id': segmentId,
        'text_id': textId,
        'content_index': 0,
        'language': language,
      });

      final response = await client
          .post(uri, body: body, headers: {'Content-Type': 'application/json'})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final shortUrl = data['shortUrl'];
        if (shortUrl == null || shortUrl.toString().isEmpty) {
          throw Exception('Missing or empty shortUrl in response');
        }

        return shortUrl.toString();
      } else if (response.statusCode == 404) {
        throw Exception('Share endpoint not found');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error: ${response.statusCode}');
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } on FormatException catch (e) {
      _logger.error('Invalid JSON response', e);
      throw Exception('Invalid JSON response: $e');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }
}
