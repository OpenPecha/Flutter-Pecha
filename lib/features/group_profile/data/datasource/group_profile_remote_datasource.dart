import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_member_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

class GroupProfileRemoteDatasource {
  final Dio dio;
  final _logger = AppLogger('GroupProfileRemoteDatasource');

  GroupProfileRemoteDatasource({required this.dio});

  Future<GroupProfileModel> fetchGroupProfile(
    String groupId, {
    required String language,
  }) async {
    try {
      final response = await dio.get(
        '/author/groups/$groupId',
        queryParameters: {'language': language},
        options: Options(extra: {'no_cache': true}),
      );

      if (response.statusCode == 200) {
        return GroupProfileModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group profile $groupId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group profile',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupProfile', e);
      throw _dioToException(e, 'Failed to load group profile');
    }
  }

  Future<void> followGroup(String groupId, GroupType groupType) async {
    final action = groupType.isPage ? 'follow' : 'join';
    try {
      final response = await dio.post('/author/groups/$groupId/$action');
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          groupType.isPage ? 'Failed to follow group' : 'Failed to join group',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in followGroup', e);
      throw _dioToException(
        e,
        groupType.isPage ? 'Failed to follow group' : 'Failed to join group',
      );
    }
  }

  Future<bool> checkFollowStatus(String groupId, GroupType groupType) async {
    final path =
        groupType.isPage
            ? '/users/me/following/author/groups'
            : '/users/me/joined/author/groups';
    try {
      final response = await dio.get(
        path,
        queryParameters: {'group_id': groupId, 'skip': 0, 'limit': 20},
        options: Options(
          extra: {'no_cache': true},
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      _logger.error('Dio error in checkFollowStatus', e);
      throw _dioToException(
        e,
        groupType.isPage
            ? 'Failed to check follow status'
            : 'Failed to check join status',
      );
    }
  }

  Future<GroupMembersPageModel> fetchGroupMembers(
    String groupId, {
    required int skip,
    required int limit,
  }) async {
    try {
      final response = await dio.get(
        '/author/groups/$groupId/members',
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return GroupMembersPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group members $groupId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group members',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupMembers', e);
      throw _dioToException(e, 'Failed to load group members');
    }
  }

  Future<GroupEventsPageModel> fetchGroupEvents(String groupId) async {
    try {
      final response = await dio.get(
        '/events',
        queryParameters: {'group_id': groupId},
      );

      if (response.statusCode == 200) {
        return GroupEventsPageModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        _logger.error(
          'Failed to load group events $groupId: ${response.statusCode}',
        );
        throw _statusToException(
          response.statusCode,
          'Failed to load group events',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in fetchGroupEvents', e);
      throw _dioToException(e, 'Failed to load group events');
    }
  }

  Future<void> unfollowGroup(String groupId, GroupType groupType) async {
    final action = groupType.isPage ? 'follow' : 'join';
    try {
      final response = await dio.delete('/author/groups/$groupId/$action');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _statusToException(
          response.statusCode,
          groupType.isPage
              ? 'Failed to unfollow group'
              : 'Failed to leave group',
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error in unfollowGroup', e);
      throw _dioToException(
        e,
        groupType.isPage ? 'Failed to unfollow group' : 'Failed to leave group',
      );
    }
  }

  Exception _statusToException(int? statusCode, String label) {
    if (statusCode == 401) {
      return const AuthenticationException('Unauthorized');
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
