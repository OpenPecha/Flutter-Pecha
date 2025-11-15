import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/network/api_client_provider.dart';
import 'package:flutter_pecha/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  // Future<void> loginWithGoogle();

  // Future<void> loginWithApple();

  Future<UserModel> getCurrentUser();

  // Future<Credentials?> refreshToken();

  // Future<void> logout();
}

class AuthRemoteDatasourceImpl extends AuthRemoteDataSource {
  final ApiClient _apiClient;
  final String baseUrl = dotenv.env['BASE_API_URL']!;

  AuthRemoteDatasourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<UserModel> getCurrentUser() async {
    debugPrint('Getting current user from API...');
    try {
      final response = await _apiClient.get(Uri.parse('$baseUrl/users/info'));

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded);
        return UserModel.fromJson(jsonData);
      } else {
        throw ServerException('User data not found in response');
      }
    } catch (e) {
      throw ServerException('Failed to get current user: ${e.toString()}');
    }
  }
}
