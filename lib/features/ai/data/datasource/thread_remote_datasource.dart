import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/models/chat_thread.dart';
import 'package:http/http.dart' as http;

/// Remote data source for thread operations
class ThreadRemoteDatasource {
  final http.Client _client;
  final _logger = AppLogger('ThreadRemoteDatasource');

  ThreadRemoteDatasource(this._client);

  /// Get list of all threads
  Future<ThreadListResponse> getThreads({
    required String email,
    int skip = 0,
    int limit = 10,
  }) async {
    final aiUrl = dotenv.env['AI_URL'];
    if (aiUrl == null || aiUrl.isEmpty) {
      _logger.error('AI_URL not configured in .env');
      throw Exception('AI_URL not configured');
    }

    final url = Uri.parse('$aiUrl/threads').replace(
      queryParameters: {
        'email': email,
        'application': 'webuddhist',
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );

    _logger.info('Fetching threads: ${url.toString()}');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded) as Map<String, dynamic>;
        
        _logger.info('Successfully fetched threads');
        return ThreadListResponse.fromJson(jsonData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.error('Authentication error: ${response.statusCode}');
        throw Exception('Authentication required. Please log in.');
      } else {
        _logger.error('Failed to fetch threads: ${response.statusCode}');
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Network error fetching threads', e);
      throw Exception('Unable to load chat history. Please check your connection.');
    }
  }

  /// Get specific thread by ID with all messages
  Future<ChatThreadDetail> getThreadById(String threadId) async {
    final aiUrl = dotenv.env['AI_URL'];
    if (aiUrl == null || aiUrl.isEmpty) {
      _logger.error('AI_URL not configured in .env');
      throw Exception('AI_URL not configured');
    }

    final url = Uri.parse('$aiUrl/threads/$threadId');
    
    _logger.info('Fetching thread details: ${url.toString()}');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(decoded) as Map<String, dynamic>;
        
        _logger.info('Successfully fetched thread: $threadId');
        return ChatThreadDetail.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        _logger.error('Thread not found: $threadId');
        throw Exception('Conversation not found');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _logger.error('Authentication error: ${response.statusCode}');
        throw Exception('Authentication required. Please log in.');
      } else {
        _logger.error('Failed to fetch thread: ${response.statusCode}');
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      _logger.error('Network error fetching thread', e);
      throw Exception('Unable to load conversation. Please check your connection.');
    }
  }
}

