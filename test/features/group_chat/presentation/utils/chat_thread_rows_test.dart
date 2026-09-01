import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:flutter_test/flutter_test.dart';

ChatMessageDTO _message({
  required String id,
  required String senderId,
  required String createdAt,
}) {
  return ChatMessageDTO(
    id: id,
    roomId: 'room-1',
    senderId: senderId,
    senderEmail: '$senderId@example.com',
    body: 'body $id',
    createdAt: createdAt,
  );
}

void main() {
  group('parseChatTimestamp', () {
    test('reads a zoneless server timestamp as UTC', () {
      final withZone = parseChatTimestamp('2026-08-28T10:00:00Z');
      final without = parseChatTimestamp('2026-08-28T10:00:00');
      expect(without, withZone);
    });

    test('reads the offset form the API actually sends', () {
      // e.g. 2026-08-31T10:18:53.143679+00:00 — microseconds plus an offset.
      final offset = parseChatTimestamp('2026-08-31T10:18:53.143679+00:00');
      final zulu = parseChatTimestamp('2026-08-31T10:18:53.143679Z');
      expect(offset, zulu);
      expect(offset.toUtc().hour, 10);
    });

    test('falls back to the epoch on unparseable input', () {
      expect(
        parseChatTimestamp('not a date').millisecondsSinceEpoch,
        0,
      );
    });
  });

  group('buildChatThreadRows', () {
    test('adds one separator per day, below that day oldest message', () {
      // Newest-first, 48h apart so the local day differs in every timezone.
      final messages = [
        _message(id: 'm3', senderId: 'a', createdAt: '2026-08-28T12:00:00Z'),
        _message(id: 'm2', senderId: 'a', createdAt: '2026-08-26T12:00:00Z'),
        _message(id: 'm1', senderId: 'a', createdAt: '2026-08-24T12:00:00Z'),
      ];

      final rows = buildChatThreadRows(messages);

      expect(rows.length, 6);
      expect((rows[0] as ChatMessageRow).message.id, 'm3');
      expect(rows[1], isA<ChatDateRow>());
      expect((rows[2] as ChatMessageRow).message.id, 'm2');
      expect(rows[3], isA<ChatDateRow>());
      expect((rows[4] as ChatMessageRow).message.id, 'm1');
      expect(rows[5], isA<ChatDateRow>());
    });

    test('groups a same-day run under a single separator', () {
      final messages = [
        _message(id: 'm2', senderId: 'a', createdAt: '2026-08-28T12:01:00Z'),
        _message(id: 'm1', senderId: 'a', createdAt: '2026-08-28T12:00:00Z'),
      ];

      final rows = buildChatThreadRows(messages);

      expect(rows.whereType<ChatDateRow>().length, 1);
      expect(rows.last, isA<ChatDateRow>());
    });

    test('marks only the first message of a run', () {
      final messages = [
        _message(id: 'm3', senderId: 'a', createdAt: '2026-08-28T12:02:00Z'),
        _message(id: 'm2', senderId: 'a', createdAt: '2026-08-28T12:01:00Z'),
        _message(id: 'm1', senderId: 'a', createdAt: '2026-08-28T12:00:00Z'),
      ];

      final rows = buildChatThreadRows(messages).whereType<ChatMessageRow>();
      final byId = {for (final row in rows) row.message.id: row};

      // m1 is oldest — the top of the run — so it carries avatar and name.
      expect(byId['m1']!.isRunStart, isTrue);
      expect(byId['m2']!.isRunStart, isFalse);
      expect(byId['m3']!.isRunStart, isFalse);
    });

    test('breaks a run when the sender changes', () {
      final messages = [
        _message(id: 'm2', senderId: 'b', createdAt: '2026-08-28T12:01:00Z'),
        _message(id: 'm1', senderId: 'a', createdAt: '2026-08-28T12:00:00Z'),
      ];

      final rows = buildChatThreadRows(messages).whereType<ChatMessageRow>();
      final byId = {for (final row in rows) row.message.id: row};

      for (final id in ['m1', 'm2']) {
        expect(byId[id]!.isRunStart, isTrue, reason: id);
      }
    });

    test('breaks a run across a day boundary for the same sender', () {
      final messages = [
        _message(id: 'm2', senderId: 'a', createdAt: '2026-08-28T12:00:00Z'),
        _message(id: 'm1', senderId: 'a', createdAt: '2026-08-26T12:00:00Z'),
      ];

      final rows = buildChatThreadRows(messages).whereType<ChatMessageRow>();

      expect(rows.every((row) => row.isRunStart), isTrue);
    });

    test('returns no rows for an empty thread', () {
      expect(buildChatThreadRows(const []), isEmpty);
    });
  });

  group('chatDateLabelKind', () {
    final now = DateTime(2026, 8, 28, 15, 30);

    test('labels the current day as today', () {
      expect(
        chatDateLabelKind(DateTime(2026, 8, 28, 1), now),
        ChatDateLabelKind.today,
      );
    });

    test('labels the previous day as yesterday', () {
      expect(
        chatDateLabelKind(DateTime(2026, 8, 27, 23), now),
        ChatDateLabelKind.yesterday,
      );
    });

    test('labels an earlier day this year without a year', () {
      expect(
        chatDateLabelKind(DateTime(2026, 3, 2), now),
        ChatDateLabelKind.thisYear,
      );
    });

    test('labels a previous year with a year', () {
      expect(
        chatDateLabelKind(DateTime(2025, 12, 31), now),
        ChatDateLabelKind.older,
      );
    });

    test('treats yesterday as a calendar day, not 24 hours', () {
      // Guards the DST case where subtracting a Duration lands off-midnight.
      final newYear = DateTime(2027, 1, 1, 0, 30);
      expect(
        chatDateLabelKind(DateTime(2026, 12, 31, 23, 59), newYear),
        ChatDateLabelKind.yesterday,
      );
    });
  });
}
