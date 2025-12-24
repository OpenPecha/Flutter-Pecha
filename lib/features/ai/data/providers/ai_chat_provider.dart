import 'package:flutter_pecha/features/ai/data/datasource/ai_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/datasource/thread_datasource_dummy.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final aiChatDatasourceProvider = Provider<AiChatRemoteDatasource>((ref) {
  final client = ref.watch(httpClientProvider);
  return AiChatRemoteDatasource(client);
});

final threadDatasourceDummyProvider = Provider<ThreadDatasourceDummy>((ref) {
  return ThreadDatasourceDummy();
});

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final datasource = ref.watch(aiChatDatasourceProvider);
  final threadDatasource = ref.watch(threadDatasourceDummyProvider);
  return AiChatRepository(datasource, threadDatasource);
});

