import 'package:flutter_pecha/features/push_notifications/presentation/push_message_navigator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolvePushTap for group pushes', () {
    test('EVENT_REMINDER opens the event, same as EVENT', () {
      final reminder = resolvePushTap({
        'session_type': 'EVENT_REMINDER',
        'notification_type': 'EVENT_REMINDER',
        'reminder_type': 'T_MINUS_10',
        'event_id': 'evt-1',
        'source_id': 'evt-1',
      });
      expect(reminder.target, PushTapTarget.eventDetail);
      expect(reminder.sourceId, 'evt-1');

      final created = resolvePushTap({
        'session_type': 'EVENT',
        'source_id': 'evt-1',
      });
      expect(created.target, reminder.target);
      expect(created.sourceId, reminder.sourceId);
    });

    test('EVENT_REMINDER without a source id falls back to Home', () {
      expect(
        resolvePushTap({'session_type': 'EVENT_REMINDER'}).target,
        PushTapTarget.home,
      );
    });

    test('group chat push opens the group chat by group id', () {
      final resolution = resolvePushTap({
        'session_type': 'CHAT',
        'chat_kind': 'GROUP',
        'room_id': 'room-1',
        'group_id': 'grp-1',
        'source_id': 'room-1',
      });
      expect(resolution.target, PushTapTarget.groupChat);
      expect(resolution.sourceId, 'grp-1');
    });

    test('group post push opens the post', () {
      final resolution = resolvePushTap({
        'session_type': 'GROUP_POST',
        'post_id': 'post-1',
        'source_id': 'post-1',
      });
      expect(resolution.target, PushTapTarget.postDetail);
      expect(resolution.sourceId, 'post-1');
    });
  });

  group('isGroupChatPushForActiveRoom', () {
    const groupChat = {
      'session_type': 'CHAT',
      'chat_kind': 'GROUP',
      'group_id': 'grp-1',
      'room_id': 'room-1',
    };

    test('matches a group chat push for the open room', () {
      expect(isGroupChatPushForActiveRoom(groupChat, 'grp-1'), isTrue);
    });

    test('ignores pushes for other groups', () {
      expect(isGroupChatPushForActiveRoom(groupChat, 'grp-2'), isFalse);
    });

    test('never matches when no chat room is open', () {
      expect(isGroupChatPushForActiveRoom(groupChat, null), isFalse);
      expect(isGroupChatPushForActiveRoom(groupChat, ''), isFalse);
    });

    test('ignores private chats and non-chat pushes for the same group', () {
      expect(
        isGroupChatPushForActiveRoom({
          'session_type': 'CHAT',
          'chat_kind': 'PRIVATE',
          'group_id': 'grp-1',
        }, 'grp-1'),
        isFalse,
      );
      expect(
        isGroupChatPushForActiveRoom({
          'session_type': 'GROUP_POST',
          'group_id': 'grp-1',
        }, 'grp-1'),
        isFalse,
      );
      expect(
        isGroupChatPushForActiveRoom({
          'session_type': 'EVENT',
          'group_id': 'grp-1',
        }, 'grp-1'),
        isFalse,
      );
    });

    test('is case-insensitive on session type and chat kind', () {
      expect(
        isGroupChatPushForActiveRoom({
          'session_type': 'chat',
          'chat_kind': 'group',
          'group_id': 'grp-1',
        }, 'grp-1'),
        isTrue,
      );
    });
  });
}
