import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/plans/models/plan_progress_model.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:http/http.dart' as http;

class UserPlansRemoteDatasource {
  final String baseUrl = dotenv.env['BASE_API_URL']!;
  final http.Client client;

  UserPlansRemoteDatasource({required this.client});

  // get user plans by user id
  Future<List<PlansModel>> getUserPlansByUserId() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/users/me/plans'));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final responseData = json.decode(decoded);
        final List<dynamic> jsonData = responseData['plans'] as List<dynamic>;
        return jsonData.map((json) => PlansModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load user plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user plans: $e');
    }
  }

  //subscribe user to a plan
  Future<bool> subscribeToPlan(String planId) async {
    final uri = Uri.parse('$baseUrl/users/me/plans');
    final body = json.encode({'plan_id': planId});
    try {
      final response = await client.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Failed to enroll user to plan: $e');
    }
  }

  // get user plan progress details
  Future<List<PlanProgressModel>> getUserPlanProgressDetails(
    String planId,
  ) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/me/plans/$planId'),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return jsonData.map((json) => PlanProgressModel.fromJson(json)).toList()
            as List<PlanProgressModel>;
      } else {
        throw Exception(
          'Failed to load user plan progress details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load user plan progress details: $e');
    }
  }
}
