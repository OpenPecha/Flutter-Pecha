import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';

class RecitationsQueryParams {
  final String? language;
  final String? search;

  RecitationsQueryParams({this.language, this.search});

  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};
    if (language != null) params['language'] = language!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    return params;
  }
}

class RecitationsRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  RecitationsRemoteDatasource({required this.client});

  // Get all recitations
  Future<List<RecitationModel>> fetchRecitations({
    RecitationsQueryParams? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/recitations',
      ).replace(queryParameters: queryParams?.toQueryParams());

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decoded) as Map<String, dynamic>;

        // Parse the nested "recitations" array from the response
        final List<dynamic> recitationsData =
            responseData['recitations'] as List<dynamic>? ?? [];

        return recitationsData
            .map(
              (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        debugPrint('Failed to fetch recitations: ${response.statusCode}');
        throw Exception('Failed to fetch recitations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching recitations: $e');
      throw Exception('Error fetching recitations: $e');
    }
  }

  // Get saved recitations
  Future<List<RecitationModel>> fetchSavedRecitations() async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/recitations');
      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decoded) as Map<String, dynamic>;
        final List<dynamic> recitationsData =
            responseData['recitations'] as List<dynamic>? ?? [];
        return recitationsData
            .map(
              (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        debugPrint('Failed to fetch saved recitations: ${response.statusCode}');
        throw Exception(
          'Failed to fetch saved recitations: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching saved recitations: $e');
      throw Exception('Error fetching saved recitations: $e');
    }
  }

  // Get recitation content by text ID
  Future<RecitationContentModel> fetchRecitationContent(
    String id, {
    required String language,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/v1/recitations/$id',
      ).replace(queryParameters: {'language': language});

      final requestBody = <String, dynamic>{};
      if (translations != null && translations.isNotEmpty) {
        requestBody['translations'] = translations;
      }
      if (transliterations != null && transliterations.isNotEmpty) {
        requestBody['transliterations'] = transliterations;
      }
      if (adaptations != null && adaptations.isNotEmpty) {
        requestBody['adaptations'] = adaptations;
      }

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded) as Map<String, dynamic>;
        return RecitationContentModel.fromJson(data);
      } else {
        debugPrint(
          'Failed to fetch recitation content: ${response.statusCode}',
        );
        throw Exception(
          'Failed to fetch recitation content: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching recitation content: $e');
      throw Exception('Error fetching recitation content: $e');
    }
  }

  // Save recitation
  Future<bool> saveRecitation(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/recitations');
      final body = json.encode({'text_id': id});
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Failed to save recitation: $e');
      throw Exception('Failed to save recitation: $e');
    }
  }

  // Unsave recitation
  Future<bool> unsaveRecitation(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/recitations/$id');
      final response = await client.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Failed to unsave recitation: $e');
      throw Exception('Failed to unsave recitation: $e');
    }
  }
}
