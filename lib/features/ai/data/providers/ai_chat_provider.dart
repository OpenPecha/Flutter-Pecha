import 'package:flutter_pecha/features/ai/data/datasource/ai_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/datasource/thread_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_pecha/features/ai/services/rate_limiter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

final rateLimiterProvider = Provider<RateLimiter>((ref) {
  return RateLimiter(
    maxRequests: 10,
    window: const Duration(minutes: 1),
  );
});

final aiChatDatasourceProvider = Provider<AiChatRemoteDatasource>((ref) {
  final client = ref.watch(httpClientProvider);
  return AiChatRemoteDatasource(client);
});

final threadRemoteDatasourceProvider = Provider<ThreadRemoteDatasource>((ref) {
  final client = ref.watch(httpClientProvider);
  return ThreadRemoteDatasource(client);
});

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final datasource = ref.watch(aiChatDatasourceProvider);
  final threadDatasource = ref.watch(threadRemoteDatasourceProvider);
  return AiChatRepository(datasource, threadDatasource);
});

