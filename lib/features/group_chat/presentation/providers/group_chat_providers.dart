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

/// The group whose chat screen is currently on screen, or null.
///
/// Set by [GroupChatScreen] on init and cleared on dispose. Read by the push
/// layer to skip the foreground heads-up for a room the user is already
/// reading; the message still arrives live over the WebSocket.
final activeGroupChatGroupIdProvider = StateProvider<String?>((ref) => null);
