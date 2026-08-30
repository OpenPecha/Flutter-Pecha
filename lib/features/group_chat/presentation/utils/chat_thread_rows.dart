import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_message_time.dart';

/// A row in the rendered thread. The list is kept **newest-first**, matching
/// both the API order and `ListView(reverse: true)`, so index 0 is the newest
/// message at the bottom of the screen.
sealed class ChatThreadRow {
  const ChatThreadRow();
}

class ChatMessageRow extends ChatThreadRow {
  final ChatMessageDTO message;

  /// First message of a same-sender run — the row that carries the avatar and,
  /// for other people, the sender name. Later rows in the run keep a gutter so
  /// the block stays aligned.
  final bool isRunStart;

  const ChatMessageRow({required this.message, required this.isRunStart});
}

class ChatDateRow extends ChatThreadRow {
  final DateTime day;

  const ChatDateRow({required this.day});
}

/// How a day separator should read relative to [now].
enum ChatDateLabelKind { today, yesterday, thisYear, older }

/// Flattens [messages] (newest-first) into rows, inserting a day separator
/// above the oldest message of each day and marking where each same-sender run
/// begins.
///
/// A run is broken by a different sender or a day boundary, so a burst of
/// messages renders as one visual block with a single avatar at its top.
List<ChatThreadRow> buildChatThreadRows(List<ChatMessageDTO> messages) {
  final rows = <ChatThreadRow>[];

  for (var i = 0; i < messages.length; i++) {
    final message = messages[i];
    final day = _dayOf(message.createdAtLocal);

    // The next entry in newest-first order is the message *above* this one.
    final older = i + 1 < messages.length ? messages[i + 1] : null;
    final startsRun =
        older == null ||
        older.senderId != message.senderId ||
        _dayOf(older.createdAtLocal) != day;

    rows.add(ChatMessageRow(message: message, isRunStart: startsRun));

    final isOldestOfDay = older == null || _dayOf(older.createdAtLocal) != day;
    if (isOldestOfDay) rows.add(ChatDateRow(day: day));
  }

  return rows;
}

/// Picks the separator wording for [day] relative to [now].
ChatDateLabelKind chatDateLabelKind(DateTime day, DateTime now) {
  final today = _dayOf(now);
  final target = _dayOf(day);
  if (target == today) return ChatDateLabelKind.today;
  // Day arithmetic, not 24h: subtracting a Duration lands off-midnight across
  // a DST boundary and the equality check would miss.
  if (target == DateTime(today.year, today.month, today.day - 1)) {
    return ChatDateLabelKind.yesterday;
  }
  return target.year == today.year
      ? ChatDateLabelKind.thisYear
      : ChatDateLabelKind.older;
}

DateTime _dayOf(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
