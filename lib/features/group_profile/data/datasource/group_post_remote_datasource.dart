import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/connect/data/models/connect_post_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_post_model.dart';

/// Group post endpoints: read side under `/groups/author`, write side under
/// the CMS author routes.
class GroupPostRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('GroupPostRemoteDatasource');

  GroupPostRemoteDatasource({required this.dio});

  Future<GroupPostPermissionModel> fetchPostPermission(String groupId) async {
    try {
      final response = await dio.get(
        '/users/me/permission/$groupId',
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupPostPermissionModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      _logger.error(
        'Failed to load post permission $groupId: ${response.statusCode}',
      );
      throw _statusToException(
        response.statusCode,
        'Failed to load post permission',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchPostPermission', e);
      throw _dioToException(e, 'Failed to load post permission');
    }
  }

  Future<ConnectPostsPageModel> fetchGroupPosts(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    try {
      final response = await dio.get(
        '/groups/author/$groupId/posts',
        queryParameters: {'skip': skip, 'limit': limit},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return ConnectPostsPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      _logger.error(
        'Failed to load group posts $groupId: ${response.statusCode}',
      );
      throw _statusToException(
        response.statusCode,
        'Failed to load group posts',
      );
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupPosts', e);
      throw _dioToException(e, 'Failed to load group posts');
    }
  }

  Future<GroupMediaUploadResponse> uploadMedia(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await dio.post('/cms/media/upload', data: formData);
      final data = response.data;
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw _statusToException(response.statusCode, 'Failed to upload media');
      }
      if (data is! Map<String, dynamic>) {
        throw const ServerException('Unexpected media upload payload');
      }

      final upload = GroupMediaUploadResponse.fromJson(data);
      if (upload.key.isEmpty) {
        throw const ServerException('Media upload returned no key');
      }
      return upload;
    } on DioException catch (e) {
      _logger.error('Dio error in uploadMedia', e);
      throw _dioToException(e, 'Failed to upload media');
    }
  }

  Future<ConnectPostModel> createPost(
    String groupId,
    CreateGroupPostRequest request,
  ) async {
    try {
      final response = await dio.post(
        '/cms/author/groups/$groupId/posts',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ConnectPostModel.fromJson(response.data as Map<String, dynamic>);
      }

      _logger.error(
        'Failed to create post in $groupId: ${response.statusCode}',
      );
      throw _statusToException(response.statusCode, 'Failed to create post');
    } on DioException catch (e) {
      _logger.error('Dio error in createPost', e);
      throw _dioToException(e, 'Failed to create post');
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
    } else if (statusCode == 403) {
      return const AuthorizationException('Forbidden');
    } else if (statusCode == 404) {
      return const NotFoundException('Group not found');
    } else if (statusCode == 429) {
      return const RateLimitException('Too many requests');
    } else {
      return ServerException('$label: $statusCode');
    }
  }

  Exception _dioToException(DioException e, String label) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Connection timeout');
    } else if (e.type == DioExceptionType.connectionError) {
      return const NetworkException('No internet connection');
    } else if (e.response?.statusCode != null) {
      return _statusToException(e.response!.statusCode, label);
    } else {
      return const NetworkException('Network error');
    }
  }
}
