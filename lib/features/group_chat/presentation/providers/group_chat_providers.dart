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

/// Which group's chat screen is currently on top.
///
/// A plain mutable holder rather than Riverpod state on purpose: the chat
/// screen claims and releases it from `initState` and `dispose`, and Riverpod
/// forbids modifying a provider inside widget lifecycles. Nothing needs to
/// rebuild on change; the push layer only reads it at the moment a foreground
/// message arrives, to skip the heads-up for a room the user is already
/// reading (the message still arrives live over the WebSocket).
///
/// Kept as a stack, not a single slot: a chat pushed over another chat (say
/// from a push tap) takes over while it is on top, and popping it hands the
/// slot back to the still-mounted chat underneath.
class ActiveGroupChatRoom {
  final List<String> _stack = [];

  /// The group whose chat is on top, or null when no chat screen is open.
  String? get groupId => _stack.isEmpty ? null : _stack.last;

  void claim(String groupId) => _stack.add(groupId);

  /// Drops the most recent claim for [groupId] wherever it sits, so disposal
  /// order does not matter and the same group opened twice releases one at a
  /// time.
  void release(String groupId) {
    final index = _stack.lastIndexOf(groupId);
    if (index != -1) _stack.removeAt(index);
  }
}

final activeGroupChatRoomProvider = Provider<ActiveGroupChatRoom>(
  (ref) => ActiveGroupChatRoom(),
);
