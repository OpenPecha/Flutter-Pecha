import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_user_dto.dart';

class ChatMessageReactionDTO extends Equatable {
  final String emoji;
  final int count;
  final bool reactedByMe;
  final List<String> userIds;
  final List<ChatMessageReactionUserDTO> users;

  const ChatMessageReactionDTO({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
    this.userIds = const [],
    this.users = const [],
  });

  factory ChatMessageReactionDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageReactionDTO(
      emoji: json['emoji'] as String? ?? '',
      count: _readInt(json['count']),
      reactedByMe: json['reacted_by_me'] as bool? ?? false,
      userIds:
          (json['user_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          const [],
      users:
          (json['users'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChatMessageReactionUserDTO.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'count': count,
      'reacted_by_me': reactedByMe,
      'user_ids': userIds,
      'users': users.map((user) => user.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [emoji, count, reactedByMe, userIds, users];
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
