import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/group_chat/chat_moderation.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatSendErrorKind', () {
    test('maps AuthorizationFailure to notAMember', () {
      expect(
        chatSendErrorKind(
          const AuthorizationFailure('sendGroupMessage: Forbidden'),
        ),
        ChatSendErrorKind.notAMember,
      );
    });

    test('maps AuthorizationException to notAMember', () {
      expect(
        chatSendErrorKind(const AuthorizationException('Forbidden')),
        ChatSendErrorKind.notAMember,
      );
    });

    test('maps INAPPROPRIATE_LANGUAGE before generic failures', () {
      expect(
        chatSendErrorKind(
          const ValidationFailure(
            'blocked',
            code: ChatModeration.inappropriateLanguage,
          ),
        ),
        ChatSendErrorKind.inappropriate,
      );
    });

    test('other failures stay generic', () {
      expect(
        chatSendErrorKind(const ValidationFailure('bad request')),
        ChatSendErrorKind.generic,
      );
    });
  });
}
