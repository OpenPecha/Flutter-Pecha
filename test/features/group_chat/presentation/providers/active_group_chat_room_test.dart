import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActiveGroupChatRoom', () {
    test('starts empty and reports the claimed room', () {
      final room = ActiveGroupChatRoom();
      expect(room.groupId, isNull);

      room.claim('a');
      expect(room.groupId, 'a');

      room.release('a');
      expect(room.groupId, isNull);
    });

    test(
      'a chat pushed over another takes over, and popping it hands back',
      () {
        final room = ActiveGroupChatRoom()..claim('a');

        room.claim('b');
        expect(room.groupId, 'b');

        // Chat B popped: A is on screen again and must be muted again.
        room.release('b');
        expect(room.groupId, 'a');

        room.release('a');
        expect(room.groupId, isNull);
      },
    );

    test('disposal order does not matter', () {
      final room =
          ActiveGroupChatRoom()
            ..claim('a')
            ..claim('b');

      // A route replaced underneath B disposes first.
      room.release('a');
      expect(room.groupId, 'b');

      room.release('b');
      expect(room.groupId, isNull);
    });

    test('the same group opened twice releases one claim at a time', () {
      final room =
          ActiveGroupChatRoom()
            ..claim('a')
            ..claim('a');

      room.release('a');
      expect(room.groupId, 'a');

      room.release('a');
      expect(room.groupId, isNull);
    });

    test('releasing an unknown group is a no-op', () {
      final room = ActiveGroupChatRoom()..claim('a');
      room.release('zzz');
      expect(room.groupId, 'a');
    });
  });
}
