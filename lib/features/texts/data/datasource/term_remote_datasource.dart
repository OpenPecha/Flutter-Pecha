// lib/features/texts/data/datasources/term_remote_datasource.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/texts/models/term.dart';
import 'package:http/http.dart' as http;

class TermRemoteDatasource {
  final http.Client client;

  TermRemoteDatasource({required this.client});

  Future<List<Term>> fetchTerms() async {
    final response = await client.get(
      Uri.parse('${dotenv.env['BASE_API_URL']}/terms'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      final List<dynamic> termsJson = jsonMap['terms'] ?? [];
      return termsJson
          .map((json) => Term.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load terms');
    }
  }
}
