import 'package:equatable/equatable.dart';

class ChatMessageParentDTO extends Equatable {
  final String id;
  final String senderId;
  final String senderEmail;

  /// Present since the API started stamping identity onto messages; null on
  /// rows written before that, which keeps the email fallback alive.
  final String? senderName;
  final String? senderAvatarUrl;
  final String body;
  final String createdAt;

  const ChatMessageParentDTO({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    this.senderName,
    this.senderAvatarUrl,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessageParentDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageParentDTO(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderEmail: json['sender_email'] as String? ?? '',
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_email': senderEmail,
      if (senderName != null) 'sender_name': senderName,
      if (senderAvatarUrl != null) 'sender_avatar_url': senderAvatarUrl,
      'body': body,
      'created_at': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    senderEmail,
    senderName,
    senderAvatarUrl,
    body,
    createdAt,
  ];
}
