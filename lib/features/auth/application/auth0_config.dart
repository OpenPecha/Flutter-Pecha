import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Auth0Config {
  final String domain;
  final String clientId;

  Auth0Config({required this.domain, required this.clientId});

  factory Auth0Config.fromJson(Map<String, dynamic> json) {
    return Auth0Config(
      domain: json['domain'] as String,
      clientId: json['client_id'] as String,
    );
  }
}

Future<Auth0Config> fetchAuth0Config() async {
  final baseUrl = dotenv.env['BASE_API_URL'];
  if (baseUrl == null) {
    throw Exception('BASE_API_URL not set in .env');
  }
  final response = await http.get(Uri.parse('$baseUrl/props'));
  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    return Auth0Config.fromJson(jsonData);
  } else {
    throw Exception('Failed to load Auth0 config');
  }
}
