import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:http/http.dart' as http;

class AiChatRemoteDatasource {
  final http.Client _client;
  final _logger = AppLogger('AiChatRemoteDatasource');

  AiChatRemoteDatasource(this._client);

  Stream<Map<String, dynamic>> sendMessage(String message) async* {
    final aiUrl = dotenv.env['AI_URL'];
    if (aiUrl == null || aiUrl.isEmpty) {
      _logger.error('AI_URL not configured in .env');
      throw Exception('AI_URL not configured');
    }

    final url = Uri.parse('$aiUrl/api/chat/stream');
    
    final requestBody = {
      'messages': [
        {
          'role': 'user',
          'content': message,
        }
      ]
    };

    _logger.info('Sending message to AI API: ${url.toString()}');
    
    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';
      request.body = jsonEncode(requestBody);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        _logger.error('API error: ${streamedResponse.statusCode}');
        throw Exception('API returned status ${streamedResponse.statusCode}');
      }

      _logger.info('Receiving stream from API');

      // Buffer for incomplete lines across chunks
      String buffer = '';

      // Parse the SSE stream with proper buffering
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
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

