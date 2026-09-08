import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_room_cache.dart';
import 'package:flutter_pecha/features/group_chat/data/repositories/group_chat_repository_impl.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
import 'package:flutter_pecha/features/group_chat/domain/usecases/resolve_group_chat_room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groupChatRemoteDatasourceProvider = Provider<GroupChatRemoteDatasource>((
  ref,
) {
  return GroupChatRemoteDatasource(dio: ref.watch(dioProvider));
});

final groupChatRepositoryProvider = Provider<GroupChatRepository>((ref) {
  return GroupChatRepositoryImpl(
    remote: ref.watch(groupChatRemoteDatasourceProvider),
  );
});

final groupChatRoomCacheProvider = Provider<GroupChatRoomCache>((ref) {
  return GroupChatRoomCache(storage: ref.watch(storageServiceProvider));
});

final resolveGroupChatRoomProvider = Provider<ResolveGroupChatRoom>((ref) {
  return ResolveGroupChatRoom(
    repository: ref.watch(groupChatRepositoryProvider),
    cache: ref.watch(groupChatRoomCacheProvider),
  );
});

/// Which group's chat screen is currently on screen.
///
/// A plain mutable holder rather than Riverpod state on purpose: the chat
/// screen claims and releases it from `initState` and `dispose`, and Riverpod
/// forbids modifying a provider inside widget lifecycles. Nothing needs to
/// rebuild on change; the push layer only reads it at the moment a foreground
/// message arrives, to skip the heads-up for a room the user is already
/// reading (the message still arrives live over the WebSocket).
class ActiveGroupChatRoom {
  String? _groupId;

  String? get groupId => _groupId;

  void claim(String groupId) => _groupId = groupId;

  /// Only clears when [groupId] still holds the slot, so a chat for another
  /// group pushed on top keeps its own claim when this one disposes.
  void release(String groupId) {
    if (_groupId == groupId) _groupId = null;
  }
}

final activeGroupChatRoomProvider = Provider<ActiveGroupChatRoom>(
  (ref) => ActiveGroupChatRoom(),
);
