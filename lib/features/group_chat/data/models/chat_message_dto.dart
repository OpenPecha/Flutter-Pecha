import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_parent_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';

class ChatMessageDTO extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String senderEmail;
  final String body;
  final String createdAt;
  final ChatMessageParentDTO? parent;
  final List<ChatMessageReactionDTO> reactions;

  const ChatMessageDTO({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderEmail,
    required this.body,
    required this.createdAt,
    this.parent,
    this.reactions = const [],
  });

  factory ChatMessageDTO.fromJson(Map<String, dynamic> json) {
    final parentJson = json['parent'];
    return ChatMessageDTO(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderEmail: json['sender_email'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      parent:
          parentJson is Map<String, dynamic>
              ? ChatMessageParentDTO.fromJson(parentJson)
              : null,
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChatMessageReactionDTO.fromJson)
              .toList() ??
          const [],
    );
  }

  /// Additive: only the fields a live update rewrites are parameterised, so
  /// the task 0 round-trip tests are untouched.
  ChatMessageDTO copyWith({
    String? body,
    List<ChatMessageReactionDTO>? reactions,
  }) {
    return ChatMessageDTO(
      id: id,
      roomId: roomId,
      senderId: senderId,
      senderEmail: senderEmail,
      body: body ?? this.body,
      createdAt: createdAt,
      parent: parent,
      reactions: reactions ?? this.reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_email': senderEmail,
      'body': body,
      'created_at': createdAt,
      if (parent != null) 'parent': parent!.toJson(),
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    roomId,
    senderId,
    senderEmail,
    body,
    createdAt,
    parent,
    reactions,
  ];
}
