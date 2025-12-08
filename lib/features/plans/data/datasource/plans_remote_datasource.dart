import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:http/http.dart' as http;

/// Query parameters for filtering and paginating plans
///
class PlansQueryParams {
  final String? search;
  final String? language;
  final int? skip;
  final int? limit;

  const PlansQueryParams({
    this.search,
    this.language,
    this.skip = 0,
    this.limit = 20,
  });

  /// Convert to query parameters map
  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (language != null) {
      params['language'] = language!;
    }

    if (search != null && search!.isNotEmpty) {
      params['search'] = search!;
    }

    params['skip'] = skip.toString();
    params['limit'] = limit.toString();

    return params;
  }
}

class PlansRemoteDatasource {
  final http.Client client;
  final String baseUrl = dotenv.env['BASE_API_URL']!;
  final _logger = AppLogger('PlansRemoteDatasource');

  PlansRemoteDatasource({required this.client});

  // get all plans with filtering and pagination
  Future<List<PlansModel>> fetchPlans({
    required PlansQueryParams queryParams,
  }) async {
    try {
      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/plans',
      ).replace(queryParameters: queryParams.toQueryParams());

      final response = await client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decoded);
        final List<dynamic> jsonData = responseData['plans'] as List<dynamic>;
        return jsonData.map((json) => PlansModel.fromJson(json)).toList();
      } else {
        _logger.error('Failed to load plans: ${response.statusCode}');
        throw Exception('Failed to load plans: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error in fetchPlans', e);
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
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return PlansModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load plan: $e');
    }
  }
}
