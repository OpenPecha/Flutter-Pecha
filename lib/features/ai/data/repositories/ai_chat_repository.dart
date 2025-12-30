import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/data/datasource/ai_chat_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/data/datasource/thread_remote_datasource.dart';
import 'package:flutter_pecha/features/ai/models/chat_message.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';

/// Event types emitted by the chat stream
abstract class ChatStreamEvent {}

class SearchResultsEvent extends ChatStreamEvent {
  final List<SearchResult> results;
  SearchResultsEvent(this.results);
}

class TokenEvent extends ChatStreamEvent {
  final String token;
  TokenEvent(this.token);
}

class DoneEvent extends ChatStreamEvent {}

class ThreadIdEvent extends ChatStreamEvent {
  final String threadId;
  ThreadIdEvent(this.threadId);
}

class ErrorEvent extends ChatStreamEvent {
  final String message;
  ErrorEvent(this.message);
}

class AiChatRepository {
  final AiChatRemoteDatasource _datasource;
  final ThreadRemoteDatasource _threadDatasource;
  final _logger = AppLogger('AiChatRepository');

  AiChatRepository(this._datasource, this._threadDatasource);

  /// Sends a message and returns a stream of chat events
  Stream<ChatStreamEvent> sendMessage({
    required String message,
    required String email,
    String? threadId,
  }) async* {
    try {
      await for (final data in _datasource.sendMessage(
        message: message,
        email: email,
        threadId: threadId,
      )) {
        final type = data['type'] as String?;
        
        // Check if this is the thread_id response (no type field)
        if (type == null && data.containsKey('thread_id')) {
          final receivedThreadId = data['thread_id'] as String?;
          if (receivedThreadId != null && receivedThreadId.isNotEmpty) {
            _logger.info('Received thread_id: $receivedThreadId');
            yield ThreadIdEvent(receivedThreadId);
          }
          continue;
        }
        
        switch (type) {
          case 'search_results':
            final resultsData = (data['data'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ?? [];
            
            final results = resultsData
                .map((json) => SearchResult.fromJson(json))
                .toList();
            
            _logger.debug('Received ${results.length} search results');
            yield SearchResultsEvent(results);
            break;
            
          case 'token':
            final token = data['data'] as String? ?? '';
            yield TokenEvent(token);
            break;
            
          case 'done':
            _logger.info('Stream completed');
            yield DoneEvent();
            break;
            
          default:
            _logger.warning('Unknown event type: $type');
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Error in chat stream', e, stackTrace);
      yield ErrorEvent(e.toString());
    }
  }

  /// Get list of threads
  Future<ThreadListResponse> getThreads({
    required String email,
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      _logger.info('Fetching threads (email: $email, skip: $skip, limit: $limit)');
      return await _threadDatasource.getThreads(
        email: email,
        skip: skip,
        limit: limit,
      );
    } catch (e, stackTrace) {
      _logger.error('Error fetching threads', e, stackTrace);
      rethrow;
    }
  }

  /// Get specific thread by ID
  Future<ChatThreadDetail> getThreadById(String threadId) async {
    try {
      _logger.info('Fetching thread: $threadId');
      return await _threadDatasource.getThreadById(threadId);
    } catch (e, stackTrace) {
      _logger.error('Error fetching thread $threadId', e, stackTrace);
      rethrow;
    }
  }
}

