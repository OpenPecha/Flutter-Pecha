import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';
import 'package:http/http.dart' as http;

/// Remote datasource for saving onboarding preferences to backend
class OnboardingRemoteDatasource {
  const OnboardingRemoteDatasource({required this.client});

  final http.Client client;

  /// Save onboarding preferences to backend
  ///
  /// TODO: Backend implementation required
  /// Endpoint: POST /api/v1/users/me/onboarding-preferences
  /// Body: JSON with familiarityLevel, preferredLanguage, selectedPaths
  /// Returns: Success boolean
  Future<bool> saveOnboardingPreferences(OnboardingPreferences prefs) async {
    try {
      final baseUrl = dotenv.env['BASE_API_URL'];
      if (baseUrl == null) {
        debugPrint('BASE_API_URL not configured');
        return false;
      }

      final uri = Uri.parse('$baseUrl/users/me/onboarding-preferences');
      final body = json.encode(prefs.toJson());

      final response = await client.post(
        uri,
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Onboarding preferences saved to backend successfully');
        return true;
      } else {
        debugPrint(
          'Failed to save onboarding preferences: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error saving onboarding preferences to backend: $e');
      return false;
    }
  }
}
