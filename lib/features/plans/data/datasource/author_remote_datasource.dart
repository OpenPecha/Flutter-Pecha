import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/author_model.dart';

class AuthorRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

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
        throw Exception('Failed to load author: ${response.statusCode}');
      }
    } catch (e) {
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
        final jsonData = json.decode(response.body);
        return jsonData.map((json) => PlansModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plans: $e');
    }
  }
}
