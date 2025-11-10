import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';

class RecitationsQueryParams {
  final String? language;
  final String? search;

  RecitationsQueryParams({this.language, this.search});

  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};
    if (language != null) params['language'] = language!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    return params;
  }
}

class RecitationsRemoteDatasource {
  final http.Client client;

  RecitationsRemoteDatasource({required this.client});

  Future<List<RecitationModel>> fetchRecitations({
    RecitationsQueryParams? queryParams,
  }) async {
    try {
      // final uri = Uri.parse(
      //   '/recitations',
      // ).replace(queryParameters: queryParams?.toQueryParams());
      // final response = await client.get(uri);
      // if (response.statusCode == 200) {
      // final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      // return data
      //     .map(
      //       (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
      //     )
      //     .toList();
      return mockRecitations;
      // } else {
      //   throw Exception('Failed to fetch recitations: ${response.statusCode}');
      // }
    } catch (e) {
      throw Exception('Error fetching recitations: $e');
    }
  }

  Future<List<RecitationModel>> fetchSavedRecitations() async {
    try {
      final uri = Uri.parse('/recitations/saved');
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map(
              (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Failed to fetch saved recitations: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching saved recitations: $e');
    }
  }

  Future<RecitationContentModel> fetchRecitationContent(String id) async {
    try {
      final uri = Uri.parse('/recitations/$id');
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return RecitationContentModel.fromJson(data);
      } else {
        throw Exception(
          'Failed to fetch recitation content: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching recitation content: $e');
    }
  }

  Future<void> saveRecitation(String id) async {
    try {
      final uri = Uri.parse('/recitations/$id/save');
      final response = await client.post(uri);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save recitation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving recitation: $e');
    }
  }

  Future<void> unsaveRecitation(String id) async {
    try {
      final uri = Uri.parse('/recitations/$id/save');
      final response = await client.delete(uri);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to unsave recitation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unsaving recitation: $e');
    }
  }
}
