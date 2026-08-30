import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_room_cache.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';

/// Outcome of looking up the chat room that backs a group.
sealed class GroupChatRoomLookup {
  const GroupChatRoomLookup();
}

/// The group has a room this user can open.
class GroupChatRoomFound extends GroupChatRoomLookup {
  final String roomId;

  const GroupChatRoomFound(this.roomId);
}

/// The group has no room yet. The first send creates it.
class GroupChatRoomMissing extends GroupChatRoomLookup {
  const GroupChatRoomMissing();
}

/// The lookup itself failed, so whether a room exists is unknown. Distinct
/// from [GroupChatRoomMissing] so a flaky network never presents an existing
/// conversation as an empty one.
class GroupChatRoomUnavailable extends GroupChatRoomLookup {
  const GroupChatRoomUnavailable();
}

/// Finds the room for a group without requiring the user to send first.
///
/// The local cache is only a shortcut: it is checked first because it costs
/// one request, but a miss falls through to the server so a reinstall or a
/// fresh device still opens straight into the conversation.
class ResolveGroupChatRoom {
  ResolveGroupChatRoom({
    required GroupChatRepository repository,
    required GroupChatRoomCache cache,
  }) : _repository = repository,
       _cache = cache;

  final GroupChatRepository _repository;
  final GroupChatRoomCache _cache;

  /// There is no "room for this group" endpoint, so the caller's rooms are
  /// paged and matched on `group_id`. Capped: past this the first send is a
  /// cheaper way to reach the room than paging the whole list.
  static const int _pageLimit = 50;
  static const int _maxPages = 4;

  Future<GroupChatRoomLookup> call({
    required String userId,
    required String groupId,
  }) async {
    if (groupId.isEmpty) return const GroupChatRoomMissing();
    final cached = await _readFromCache(userId: userId, groupId: groupId);
    if (cached != null) return cached;
    return _findOnServer(userId: userId, groupId: groupId);
  }

  /// Returns null when the cache cannot answer and the server should be asked.
  Future<GroupChatRoomLookup?> _readFromCache({
    required String userId,
    required String groupId,
  }) async {
    final roomId = await _cache.read(userId: userId, groupId: groupId);
    if (roomId == null) return null;
    final result = await _repository.getRoom(roomId);
    final room = result.fold<ChatRoomDTO?>((_) => null, (room) => room);
    if (room != null && room.id.isNotEmpty) return GroupChatRoomFound(room.id);
    final isStale = result.fold<bool>(
      (failure) => failure is NotFoundFailure,
      (_) => false,
    );
    if (!isStale) return const GroupChatRoomUnavailable();
    await _cache.clear(userId: userId, groupId: groupId);
    return null;
  }

  Future<GroupChatRoomLookup> _findOnServer({
    required String userId,
    required String groupId,
  }) async {
    var skip = 0;
    for (var page = 0; page < _maxPages; page++) {
      final result = await _repository.listRooms(skip: skip, limit: _pageLimit);
      final rooms = result.fold<ChatRoomsPage?>((_) => null, (page) => page);
      if (rooms == null) return const GroupChatRoomUnavailable();
      final match = _matchGroupRoom(rooms.rooms, groupId);
      if (match != null) {
        await _cache.write(userId: userId, groupId: groupId, roomId: match);
        return GroupChatRoomFound(match);
      }
      skip += rooms.rooms.length;
      if (rooms.rooms.isEmpty || skip >= rooms.total) break;
    }
    return const GroupChatRoomMissing();
  }

  static String? _matchGroupRoom(List<ChatRoomDTO> rooms, String groupId) {
    for (final room in rooms) {
      if (room.groupId == groupId && room.id.isNotEmpty) return room.id;
    }
    return null;
  }
}
