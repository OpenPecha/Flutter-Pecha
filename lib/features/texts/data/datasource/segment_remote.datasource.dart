import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/commentary/segment_commentary_response.dart';
import 'package:http/http.dart' as http;

class SegmentRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  SegmentRemoteDatasource({required this.client});

  // get all segment commentaries
  Future<SegmentCommentaryResponse> getSegmentCommentaries(
    String segmentId,
  ) async {
    final response = await client.get(
      Uri.parse('$baseUrl/segments/$segmentId/commentaries'),
    );
    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> jsonMap = json.decode(decoded);

      return SegmentCommentaryResponse.fromJson(jsonMap);
    } else {
      throw Exception('Failed to load segment commentaries');
    }
  }
}
