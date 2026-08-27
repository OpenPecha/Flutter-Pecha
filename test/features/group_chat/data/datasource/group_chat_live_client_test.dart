import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/exception_mapper.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/chat_moderation.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatLiveClient', () {
    test('liveUri uses wss and /chat/live under the REST base path', () {
      final uri = ChatLiveClient.liveUri(
        restBaseUrl: 'https://api.example.com/api/v1',
        token: 'tok',
        groupId: 'g1',
      );
      expect(uri.scheme, 'wss');
      expect(uri.host, 'api.example.com');
      expect(uri.path, '/api/v1/chat/live');
      expect(uri.queryParameters['token'], 'tok');
      expect(uri.queryParameters['group_id'], 'g1');
    });

    test('liveUri maps http to ws', () {
      final uri = ChatLiveClient.liveUri(
        restBaseUrl: 'http://localhost:8000/api/v1',
        token: 'tok',
        groupId: 'g1',
      );
      expect(uri.scheme, 'ws');
    });

    test('parses error frames including INAPPROPRIATE_LANGUAGE', () {
      final event = ChatLiveClient.parseFrame(
        '{"type":"error","code":"INAPPROPRIATE_LANGUAGE","message":"blocked"}',
      );
      expect(event, isA<ChatLiveError>());
      final error = event! as ChatLiveError;
      expect(error.code, ChatModeration.inappropriateLanguage);
      expect(error.message, 'blocked');
    });
  });

  group('shared profanity code', () {
    test(
      'WS error and REST ValidationFailure share INAPPROPRIATE_LANGUAGE',
      () {
        final ws =
            ChatLiveClient.parseFrame(
              '{"type":"error","code":"INAPPROPRIATE_LANGUAGE","message":"no"}',
            )!;
        const rest = ValidationFailure(
          'no',
          code: ChatModeration.inappropriateLanguage,
        );
        expect(chatSendErrorCode(rest), chatSendErrorCode(ws));
        expect(
          ChatModeration.isInappropriateLanguage(chatSendErrorCode(rest)),
          isTrue,
        );
      },
    );

    test('ExceptionMapper keeps validation code', () {
      const exception = ValidationException(
        'blocked',
        code: ChatModeration.inappropriateLanguage,
      );
      final failure = ExceptionMapper.map(exception);
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).code,
        ChatModeration.inappropriateLanguage,
      );
    });
  });
}
