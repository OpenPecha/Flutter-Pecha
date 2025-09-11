import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:http/http.dart' as http;

/// Query parameters for filtering and paginating plans
class PlansQueryParams {
  final DifficultyLevel? difficultyLevel;
  final List<String>? tags;
  final bool? featured;
  final String? search;
  final int page;
  final int limit;

  const PlansQueryParams({
    this.difficultyLevel,
    this.tags,
    this.featured,
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  /// Convert to query parameters map
  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (difficultyLevel != null) {
      params['difficulty_level'] = difficultyLevel!.name;
    }

    if (tags != null && tags!.isNotEmpty) {
      params['tags'] = tags!.join(',');
    }

    if (featured != null) {
      params['featured'] = featured.toString();
    }

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }

    params['page'] = page.toString();
    params['limit'] = limit.toString();

    return params;
  }
}

class PlansRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  PlansRemoteDatasource({required this.client});

  // get all plans with filtering and pagination
  Future<List<PlansModel>> getPlans([PlansQueryParams? queryParams]) async {
    try {
      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/plans',
      ).replace(queryParameters: queryParams?.toQueryParams());

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> jsonData = responseData['plans'] as List<dynamic>;
        return jsonData.map((json) => PlansModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plans: $e');
    }
  }

  // get plan by id
  Future<PlansModel> getPlanById(String planId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/plans/$planId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PlansModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plan: $e');
    }
  }
}
