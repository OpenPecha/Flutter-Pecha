import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class GroupChatRepositoryImpl implements GroupChatRepository {
  GroupChatRepositoryImpl({required GroupChatRemoteDatasource remote})
    : _remote = remote;

  final GroupChatRemoteDatasource _remote;

  @override
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      return Right(await _remote.listRooms(skip: skip, limit: limit));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'listRooms'));
    }
  }

  @override
  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId) async {
    try {
      return Right(await _remote.getRoom(roomId));
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'getRoom'));
    }
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      return Right(
        await _remote.listMessages(roomId, skip: skip, limit: limit),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'listMessages'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  }) async {
    try {
      return Right(
        await _remote.sendGroupMessage(
          groupId,
          body: body,
          parentMessageId: parentMessageId,
        ),
      );
    } catch (e) {
      return Left(ExceptionMapper.map(e, context: 'sendGroupMessage'));
    }
  }
}
