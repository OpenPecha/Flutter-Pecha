import 'package:flutter_pecha/features/group_chat/data/models/chat_person_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_member_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildChatSenderDirectory', () {
    test('merges the room name with the group avatar for one user', () {
      final directory = buildChatSenderDirectory(
        members: const [
          ChatRoomMemberDTO(
            userId: 'u1',
            email: 'rena@example.com',
            firstname: 'Rena',
            lastname: 'Dolma',
            role: 'MEMBER',
            joinedAt: '2026-08-01T00:00:00Z',
          ),
        ],
        people: const [
          ChatPersonDTO(
            userId: 'u1',
            email: 'rena@example.com',
            firstname: 'Rena',
            avatarUrl: 'https://cdn.example.com/rena.png',
          ),
        ],
      );

      expect(directory['u1']!.name, 'Rena Dolma');
      expect(directory['u1']!.avatarUrl, 'https://cdn.example.com/rena.png');
    });

    test('works when only one of the two endpoints answered', () {
      final directory = buildChatSenderDirectory(
        people: const [
          ChatPersonDTO(
            userId: 'u2',
            email: 'jack@example.com',
            firstname: 'Jack',
          ),
        ],
      );

      expect(directory['u2']!.name, 'Jack');
      expect(directory['u2']!.avatarUrl, isNull);
      expect(directory, hasLength(1));
    });

    test('skips entries with no user id', () {
      final directory = buildChatSenderDirectory(
        people: const [
          ChatPersonDTO(userId: '', email: 'x@example.com', firstname: 'X'),
        ],
      );

      expect(directory, isEmpty);
    });
  });

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
    test('prefers the directory name', () {
      expect(
        chatSenderDisplayName(
          sender: const ChatSender(userId: 'u1', name: 'Rena Dolma'),
          senderEmail: 'rena@example.com',
        ),
        'Rena Dolma',
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
