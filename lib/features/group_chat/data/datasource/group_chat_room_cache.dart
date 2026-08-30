import 'package:flutter_pecha/core/storage/storage_service.dart';

/// Persists the last known chat [roomId] for a user+group pair.
///
/// There is no "does this group have a room?" API. Returning users skip
/// pre-join only when this cache still points at a live room.
class GroupChatRoomCache {
  GroupChatRoomCache({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  static String key({required String userId, required String groupId}) {
    return 'group_chat.room.$userId.$groupId';
  }

  Future<String?> read({
    required String userId,
    required String groupId,
  }) async {
    if (userId.isEmpty || groupId.isEmpty) return null;
    final value = await _storage.get<String>(
      key(userId: userId, groupId: groupId),
    );
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> write({
    required String userId,
    required String groupId,
    required String roomId,
  }) async {
    if (userId.isEmpty || groupId.isEmpty || roomId.isEmpty) return;
    await _storage.set<String>(key(userId: userId, groupId: groupId), roomId);
  }

  Future<void> clear({required String userId, required String groupId}) async {
    if (userId.isEmpty || groupId.isEmpty) return;
    await _storage.delete(key(userId: userId, groupId: groupId));
  }
}
