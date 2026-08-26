import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/group_chat/data/repositories/group_chat_repository_impl.dart';
import 'package:flutter_pecha/features/group_chat/domain/repositories/group_chat_repository.dart';
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
