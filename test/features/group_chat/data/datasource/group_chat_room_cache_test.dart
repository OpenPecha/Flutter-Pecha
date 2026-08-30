import 'package:flutter_pecha/core/storage/storage_service.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_room_cache.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements StorageService {
  final Map<String, Object> values = {};

  @override
  Future<T?> get<T>(String key) async => values[key] as T?;

  @override
  Future<bool> set<T>(String key, T value) async {
    values[key] = value as Object;
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
}

void main() {
  group('GroupChatRoomCache', () {
    test('keys isolate user and group', () {
      expect(
        GroupChatRoomCache.key(userId: 'u1', groupId: 'g1'),
        'group_chat.room.u1.g1',
      );
      expect(
        GroupChatRoomCache.key(userId: 'u1', groupId: 'g1'),
        isNot(GroupChatRoomCache.key(userId: 'u2', groupId: 'g1')),
      );
      expect(
        GroupChatRoomCache.key(userId: 'u1', groupId: 'g1'),
        isNot(GroupChatRoomCache.key(userId: 'u1', groupId: 'g2')),
      );
    });

    test('read, write, and clear are scoped to user+group', () async {
      final storage = _MemoryStorage();
      final cache = GroupChatRoomCache(storage: storage);

      await cache.write(userId: 'u1', groupId: 'g1', roomId: 'r1');
      await cache.write(userId: 'u1', groupId: 'g2', roomId: 'r2');
      await cache.write(userId: 'u2', groupId: 'g1', roomId: 'r3');

      expect(await cache.read(userId: 'u1', groupId: 'g1'), 'r1');
      expect(await cache.read(userId: 'u1', groupId: 'g2'), 'r2');
      expect(await cache.read(userId: 'u2', groupId: 'g1'), 'r3');

      await cache.clear(userId: 'u1', groupId: 'g1');
      expect(await cache.read(userId: 'u1', groupId: 'g1'), isNull);
      expect(await cache.read(userId: 'u1', groupId: 'g2'), 'r2');
      expect(await cache.read(userId: 'u2', groupId: 'g1'), 'r3');
    });
  });
}
