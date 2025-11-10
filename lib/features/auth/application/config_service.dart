import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ConfigService {
  ConfigService._internal();
  static final ConfigService _instance = ConfigService._internal();
  static ConfigService get instance => _instance;

  String? auth0Domain;
  String? auth0ClientId;
  String? auth0Audience;

  bool _isLoaded = false;

  Future<void> loadConfig() async {
    if (_isLoaded) return;
    final baseUrl = dotenv.env['BASE_API_URL'];
    if (baseUrl == null) {
      throw Exception('BASE_API_URL not set in .env');
    }
    final response = await http.get(Uri.parse('$baseUrl/props'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      auth0Domain = data['domain'];
      auth0ClientId = data['client_id'];
      auth0Audience = data['auth0Audience'];
      _isLoaded = true;
    } else {
      throw Exception('Failed to fetch auth0 config');
    }
  }
}
