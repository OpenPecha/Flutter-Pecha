import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class GroupChatRepository {
  Future<Either<Failure, ChatRoomsPage>> listRooms({
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ChatRoomDTO>> getRoom(String roomId);

  Future<Either<Failure, ChatMessagesPage>> listMessages(
    String roomId, {
    int skip = 0,
    int limit = 20,
  });

  Future<Either<Failure, ChatMessageDTO>> sendGroupMessage(
    String groupId, {
    required String body,
    String? parentMessageId,
  });

  Future<Either<Failure, ChatRoomMembersPage>> listRoomMembers(
    String roomId, {
    int skip = 0,
    int limit = 100,
  });

  Future<Either<Failure, ChatPeoplePage>> listGroupPeople(
    String groupId, {
    int skip = 0,
    int limit = 100,
  });

  Future<Either<Failure, Unit>> markRoomRead(String roomId);
}
