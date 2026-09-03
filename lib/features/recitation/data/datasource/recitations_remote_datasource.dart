import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitations_page_response.dart';

/// Recitations remote datasource.
///
/// Error handling is centralized in ErrorInterceptor, which converts
/// DioExceptions to typed AppExceptions. Exceptions propagate naturally
/// to the repository layer for mapping to Failures.
class RecitationsQueryParams {
  final String? language;
  final String? search;
  final int? skip;
  final int? limit;
  final bool shouldIncludeCollections;

  RecitationsQueryParams({
    this.language,
    this.search,
    this.skip,
    this.limit,
    this.shouldIncludeCollections = false,
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    if (language != null) params['language'] = language!;
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (skip != null) params['skip'] = skip!;
    if (limit != null) params['limit'] = limit!;
    if (shouldIncludeCollections) {
      params['should_include_collections'] = 'true';
    }
    return params;
  }
}

class RecitationsRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('RecitationsRemoteDatasource');

  RecitationsRemoteDatasource({required this.dio});

  Future<RecitationsPageResponse> fetchRecitationsPage({
    RecitationsQueryParams? queryParams,
  }) async {
    final includeCollections = queryParams?.shouldIncludeCollections ?? false;
    final response = await dio.get(
      '/recitations',
      queryParameters: queryParams?.toQueryParams(),
      options:
          includeCollections
              ? Options(extra: {'no_cache': true})
              : null,
    );

    return RecitationsPageResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // Get all recitations
  Future<List<RecitationModel>> fetchRecitations({
    RecitationsQueryParams? queryParams,
  }) async {
    final page = await fetchRecitationsPage(queryParams: queryParams);
    return page.recitations;
  }

  // Get saved recitations
  Future<List<RecitationModel>> fetchSavedRecitations() async {
    final response = await dio.get('/users/me/recitations');

    final responseData = response.data as Map<String, dynamic>;
    final List<dynamic> recitationsData =
        responseData['recitations'] as List<dynamic>? ?? [];
    return recitationsData
        .map(
          (json) => RecitationModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  // Get recitation content by text ID
  Future<RecitationContentModel> fetchRecitationContent(
    String id, {
    required String language,
    List<String>? recitation,
    List<String>? translations,
    List<String>? transliterations,
    List<String>? adaptations,
  }) async {
    final requestBody = <String, dynamic>{
      'language': language,
      'recitation': recitation ?? [],
      'translations': translations ?? [],
      'transliterations': transliterations ?? [],
      'adaptations': adaptations ?? [],
    };

    _logger.debug('Fetching recitation content for ID: $id');
    _logger.debug('Request body: $requestBody');

    final response = await dio.post(
      '/recitations/$id',
      data: requestBody,
    );

    return RecitationContentModel.fromJson(response.data);
  }

  // Save recitation to user's saved recitations
  Future<bool> saveRecitation(String id) async {
    final response = await dio.post(
      '/users/me/recitations',
      data: {'text_id': id},
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Unsave recitation from user's saved recitations
  Future<bool> unsaveRecitation(String textId) async {
    final response = await dio.delete('/users/me/recitations/$textId');

    return response.statusCode == 200 || response.statusCode == 204;
  }

  // Update recitations order
  Future<bool> updateRecitationsOrder(
    List<Map<String, dynamic>> recitations,
  ) async {
    _logger.debug('Updating recitations order: $recitations');
    final response = await dio.put(
      '/users/me/recitations/order',
      data: {'recitations': recitations},
    );

    return response.statusCode == 200 || response.statusCode == 204;
  }
}
