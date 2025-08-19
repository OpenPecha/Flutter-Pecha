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
  final url = dotenv.env['AUTH0_API'];
  if (url == null) {
    throw Exception('AUTH0_API not set in .env');
  }
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    // final jsonData = json.decode(response.body);
    return Auth0Config.fromJson({
      'domain': dotenv.env['AUTH0_DOMAIN'] ?? '',
      'client_id': dotenv.env['AUTH0_CLIENT_ID'] ?? '',
    });
  } else {
    throw Exception('Failed to load Auth0 config');
  }
}
