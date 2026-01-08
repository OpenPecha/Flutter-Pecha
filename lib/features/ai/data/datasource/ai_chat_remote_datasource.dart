import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/config/ai_config.dart';
import 'package:http/http.dart' as http;

class AiChatRemoteDatasource {
  final http.Client _client;
  final _logger = AppLogger('AiChatRemoteDatasource');

  AiChatRemoteDatasource(this._client);

  Stream<Map<String, dynamic>> sendMessage({
    required String message,
    required String email,
    String? threadId,
  }) async* {
    final aiUrl = dotenv.env['AI_URL'];
    if (aiUrl == null || aiUrl.isEmpty) {
      _logger.error('AI_URL not configured in .env');
      throw Exception('AI_URL not configured');
    }

    final url = Uri.parse('$aiUrl/chats');
    
    // Build request body with required fields
    final requestBody = <String, dynamic>{
      'email': email,
      'query': message,
      'application': 'webuddhist',
      'device_type': 'mobile_app',
    };
    
    // Only include thread_id if it's provided
    if (threadId != null && threadId.isNotEmpty) {
      requestBody['thread_id'] = threadId;
      _logger.info('Sending message with thread_id: $threadId');
    } else {
      _logger.info('Sending message without thread_id (new conversation)');
    }

    _logger.info('Sending message to AI API: ${url.toString()}');
    _logger.debug('Request body: $requestBody');
    
    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      request.body = jsonEncode(requestBody);

      // Add connection timeout
      final streamedResponse = await _client.send(request).timeout(
        AiConfig.connectionTimeout,
        onTimeout: () {
          _logger.error('Connection timeout after ${AiConfig.connectionTimeout.inSeconds}s');
          throw TimeoutException(
            'Connection timed out. Please check your internet connection.',
            AiConfig.connectionTimeout,
          );
        },
      );

      if (streamedResponse.statusCode != 200) {
        _logger.error('API error: ${streamedResponse.statusCode}');
        throw Exception('API returned status ${streamedResponse.statusCode}');
      }

      _logger.info('Receiving stream from API');

      // Buffer for incomplete lines across chunks
      String buffer = '';

      // Parse the SSE stream with token timeout
      // Using stream timeout to detect stalled connections
      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .timeout(
            AiConfig.tokenTimeout,
            onTimeout: (sink) {
              _logger.error('Stream timeout - no data received for ${AiConfig.tokenTimeout.inSeconds}s');
              sink.addError(TimeoutException(
                'Response timed out. The AI server may be busy.',
                AiConfig.tokenTimeout,
              ));
              sink.close();
            },
          )) {
        // Add new chunk to buffer
        buffer += chunk;
        
        // Split by lines
        final lines = buffer.split('\n');
        
        // Keep the last line in buffer (might be incomplete)
        buffer = lines.last;
        
        // Process all complete lines (all except the last)
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          
          if (line.isEmpty) continue;
          
          // SSE format: "data: {json}"
          if (line.startsWith('data: ')) {
            final jsonString = line.substring(6); // Remove "data: " prefix
            
            try {
              final data = jsonDecode(jsonString) as Map<String, dynamic>;
              _logger.debug('Received event type: ${data['type']}');
              yield data;
            } catch (e) {
              _logger.warning('Failed to parse JSON: $jsonString');
              // Continue streaming even if one line fails
            }
          }
        }
      }
      
      // Process any remaining buffered line after stream ends
      if (buffer.trim().isNotEmpty && buffer.trim().startsWith('data: ')) {
        final jsonString = buffer.trim().substring(6);
        try {
          final data = jsonDecode(jsonString) as Map<String, dynamic>;
          _logger.debug('Received final event type: ${data['type']}');
          yield data;
        } catch (e) {
          _logger.warning('Failed to parse final buffered JSON: $jsonString');
        }
      }
      
      _logger.info('Stream completed');
    } catch (e, stackTrace) {
      _logger.error('Error in sendMessage stream', e, stackTrace);
      rethrow;
    }
  }
}

