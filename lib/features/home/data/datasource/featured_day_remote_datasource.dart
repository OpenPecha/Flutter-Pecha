import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/plans/models/response/featured_day_response.dart';
import 'package:http/http.dart' as http;

class FeaturedDayRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  FeaturedDayRemoteDatasource({required this.client});

  Future<FeaturedDayResponse> fetchFeaturedDay({String? language}) async {
    try {
      final uri = Uri.parse('$baseUrl/plans/featured/day').replace(
        queryParameters: language != null ? {'language': language} : null,
      );
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return FeaturedDayResponse.fromJson(jsonData);
      } else {
        debugPrint('Failed to load featured day: ${response.statusCode}');
        throw Exception('Failed to load featured day: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in fetchFeaturedDay: $e');
      throw Exception('Failed to load featured day: $e');
    }
  }
}
