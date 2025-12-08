import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/author/author_model.dart';

class AuthorRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;
  final _logger = AppLogger('AuthorRemoteDatasource');

  AuthorRemoteDatasource({required this.client});

  Future<AuthorModel> getAuthorById(String authorId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/authors/$authorId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AuthorModel.fromJson(jsonData);
      } else {
        _logger.error('Error to load author: ${response.statusCode}');
        throw Exception('Error to load author: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Failed to load author', e);
      throw Exception('Failed to load author: $e');
    }
  }

  // gets plans by author id
  Future<List<PlansModel>> getPlansByAuthorId(String authorId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/authors/$authorId/plans'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decoded);
        final List<dynamic> jsonData = responseData['plans'] as List<dynamic>;
        return jsonData
            .map((json) => PlansModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _logger.error('Failed to load plans: ${response.statusCode}');
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Failed to load plans', e);
      throw Exception('Failed to load plans: $e');
    }
  }
}
