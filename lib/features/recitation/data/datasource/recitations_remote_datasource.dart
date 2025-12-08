import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
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
  final _logger = AppLogger('RecitationsRemoteDatasource');

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
        _logger.error('Failed to fetch recitations: ${response.statusCode}');
        throw Exception('Failed to fetch recitations: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error fetching recitations', e);
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
        _logger.error(
          'Failed to fetch saved recitations: ${response.statusCode}',
        );
        throw Exception(
          'Failed to fetch saved recitations: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Error fetching saved recitations', e);
      throw Exception('Error fetching saved recitations: $e');
    }
  }

  // Get recitation content by text ID
  Future<RecitationContentModel> fetchRecitationContent(
    String id, {
    required String language,
    List<String>? recitation,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/recitations/$id');

      // Build request body according to API spec
      final requestBody = <String, dynamic>{
        'language': language,
        'recitation': recitation ?? [],
        'translations': translations ?? [],
        'transliterations': transliterations ?? [],
        'adaptations': adaptations ?? [],
      };

      _logger.debug('Recitation Content Request URL: $uri');
      _logger.debug(
        'Recitation Content Request Body: ${json.encode(requestBody)}',
      );

      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      _logger.debug(
        'Recitation Content Response Status: ${response.statusCode}',
      );
      if (response.statusCode != 200) {
        _logger.debug('Recitation Content Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = json.decode(decoded) as Map<String, dynamic>;
        return RecitationContentModel.fromJson(data);
      } else {
        _logger.error(
          'Failed to fetch recitation content: ${response.statusCode}',
        );
        throw Exception(
          'Failed to fetch recitation content: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.error('Error fetching recitation content', e);
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
      _logger.error('Failed to save recitation', e);
      throw Exception('Failed to save recitation: $e');
    }
  }

  // Unsave recitation
  Future<bool> unsaveRecitation(String textId) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/recitations/$textId');
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
      _logger.error('Failed to unsave recitation', e);
      throw Exception('Failed to unsave recitation: $e');
    }
  }

  // Update recitations order
  Future<bool> updateRecitationsOrder(
    List<Map<String, dynamic>> recitations,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/users/me/recitations/order');
      final body = json.encode({'recitations': recitations});
      _logger.debug('Updating recitations order: $recitations');
      final response = await client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _logger.error(
          'Failed to update recitations order: ${response.statusCode}',
        );
        _logger.debug('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.error('Failed to update recitations order', e);
      throw Exception('Failed to update recitations order: $e');
    }
  }
}
