import 'package:equatable/equatable.dart';

class ChatMessageParentDTO extends Equatable {
  final String id;
  final String senderId;
  final String senderEmail;
  final String body;
  final String createdAt;

  const ChatMessageParentDTO({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessageParentDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageParentDTO(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderEmail: json['sender_email'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_email': senderEmail,
      'body': body,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [id, senderId, senderEmail, body, createdAt];
}
