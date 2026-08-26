import 'package:dio/dio.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';

class ChatRoomsPage {
  final List<ChatRoomDTO> rooms;
  final int skip;
  final int limit;
  final int total;

  const ChatRoomsPage({
    required this.rooms,
    required this.skip,
    required this.limit,
    required this.total,
  });
}

class ChatMessagesPage {
  final List<ChatMessageDTO> messages;
  final int skip;
  final int limit;
  final int total;

  const ChatMessagesPage({
    required this.messages,
    required this.skip,
    required this.limit,
    required this.total,
  });
}

class GroupChatRemoteDatasource {
  GroupChatRemoteDatasource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static final _noCache = Options(extra: {'no_cache': true});

  Future<ChatRoomsPage> listRooms({int skip = 0, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/chat/rooms',
        queryParameters: {'skip': skip, 'limit': limit},
        options: _noCache,
      );
      final data = response.data as Map<String, dynamic>;
      return ChatRoomsPage(
        rooms:
            (data['rooms'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatRoomDTO.fromJson)
                .toList() ??
            const [],
        skip: _readInt(data['skip']),
        limit: _readInt(data['limit']),
        total: _readInt(data['total']),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<ChatRoomDTO> getRoom(String roomId) async {
    try {
      final response = await _dio.get('/chat/rooms/$roomId', options: _noCache);
      return ChatRoomDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<ChatMessagesPage> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/chat/rooms/$roomId/messages',
        queryParameters: {'skip': skip, 'limit': limit},
        options: _noCache,
      );
      final data = response.data as Map<String, dynamic>;
      return ChatMessagesPage(
        messages:
            (data['messages'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(ChatMessageDTO.fromJson)
                .toList() ??
            const [],
        skip: _readInt(data['skip']),
        limit: _readInt(data['limit']),
        total: _readInt(data['total']),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Future<ChatMessageDTO> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/groups/$groupId/messages',
        data: {
          'body': body,
          if (parentMessageId != null) 'parent_message_id': parentMessageId,
        },
      );
      return ChatMessageDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  static Exception _unwrap(DioException error) {
    final inner = error.error;
    if (inner is Exception) return inner;
    return NetworkException(error.message ?? 'Network error');
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
