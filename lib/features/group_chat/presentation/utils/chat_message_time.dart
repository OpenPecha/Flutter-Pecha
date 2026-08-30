import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';

/// `created_at` stays a `String` on [ChatMessageDTO] so the task 0 round-trip
/// tests keep passing; parsing lives here instead.
extension ChatMessageTime on ChatMessageDTO {
  DateTime get createdAtLocal => parseChatTimestamp(createdAt);
}

/// Parses a server timestamp into local time.
///
/// The API emits UTC. A value with no zone designator is therefore read as
/// UTC rather than as device-local, which is what `DateTime.parse` would
/// otherwise assume. Unparseable input falls back to the epoch so a single bad
/// row cannot take the thread down.
DateTime parseChatTimestamp(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final hasZone = RegExp(r'(Z|z|[+-]\d{2}:?\d{2})$').hasMatch(value);
  final parsed = DateTime.tryParse(hasZone ? value : '${value}Z');
  if (parsed == null) return DateTime.fromMillisecondsSinceEpoch(0);
  return parsed.toLocal();
}
