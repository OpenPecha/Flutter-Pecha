import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSelfChatMessage', () {
    test('matches on the user id', () {
      expect(
        isSelfChatMessage(
          senderId: 'u1',
          senderEmail: 'rena@example.com',
          currentUserId: 'u1',
        ),
        isTrue,
      );
    });

    test('matches on email when the id spaces differ', () {
      // Stored id is the JWT sub; sender_id is a backend UUID.
      expect(
        isSelfChatMessage(
          senderId: '2f1c-uuid',
          senderEmail: 'Rena@Example.com',
          currentUserId: 'auth0|abc123',
          currentUserEmail: 'rena@example.com',
        ),
        isTrue,
      );
    });

    test('does not match another member', () {
      expect(
        isSelfChatMessage(
          senderId: 'u2',
          senderEmail: 'jack@example.com',
          currentUserId: 'u1',
          currentUserEmail: 'rena@example.com',
        ),
        isFalse,
      );
    });

    test('does not match when nothing identifies the user', () {
      expect(
        isSelfChatMessage(
          senderId: 'u2',
          senderEmail: 'jack@example.com',
          currentUserId: '',
          currentUserEmail: null,
        ),
        isFalse,
      );
    });

    test('an empty sender email cannot match an empty stored email', () {
      expect(
        isSelfChatMessage(
          senderId: 'u2',
          senderEmail: '',
          currentUserId: '',
          currentUserEmail: '',
        ),
        isFalse,
      );
    });
  });

  group('chatSenderDisplayName', () {
    test('prefers the name carried by the message', () {
      expect(
        chatSenderDisplayName(
          messageName: 'Pema Yangchen',
          senderEmail: 'rena@example.com',
        ),
        'Pema Yangchen',
      );
    });

    test('treats a blank message name as absent', () {
      expect(
        chatSenderDisplayName(
          messageName: '   ',
          senderEmail: 'rena@example.com',
        ),
        'rena',
      );
    });

    test('falls back to the email local part', () {
      expect(
        chatSenderDisplayName(senderEmail: 'rena.dolma@example.com'),
        'rena.dolma',
      );
    });

    test('returns null when there is nothing to show', () {
      expect(chatSenderDisplayName(senderEmail: ''), isNull);
    });
  });

  group('chatSenderInitials', () {
    test('takes one letter from each of the first two words', () {
      expect(chatSenderInitials('Rena Dolma'), 'RD');
    });

    test('splits an email local part on its separators', () {
      expect(chatSenderInitials('rena.dolma'), 'RD');
    });

    test('uses a single letter for a one-word name', () {
      expect(chatSenderInitials('Jack'), 'J');
    });

    test('falls back to a placeholder for an empty name', () {
      expect(chatSenderInitials(''), '?');
      expect(chatSenderInitials(null), '?');
    });
  });

  group('chatReconnectDelay', () {
    test('doubles from one second', () {
      expect(chatReconnectDelay(1), const Duration(seconds: 1));
      expect(chatReconnectDelay(2), const Duration(seconds: 2));
      expect(chatReconnectDelay(3), const Duration(seconds: 4));
      expect(chatReconnectDelay(4), const Duration(seconds: 8));
      expect(chatReconnectDelay(5), const Duration(seconds: 16));
    });

    test('caps at thirty seconds', () {
      expect(chatReconnectDelay(6), const Duration(seconds: 30));
      expect(chatReconnectDelay(50), const Duration(seconds: 30));
    });

    test('treats a non-positive attempt as the first retry', () {
      expect(chatReconnectDelay(0), const Duration(seconds: 1));
    });
  });
}
