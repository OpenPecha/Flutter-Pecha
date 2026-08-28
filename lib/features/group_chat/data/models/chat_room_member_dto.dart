import 'package:equatable/equatable.dart';

/// A member of a chat room, from `GET /chat/rooms/{room_id}/members`.
///
/// Carries no avatar — the group people endpoint is the only source of
/// `avatar_url` keyed by `user_id`, so the two are merged into a
/// `ChatSender` for rendering.
class ChatRoomMemberDTO extends Equatable {
  final String userId;
  final String email;
  final String firstname;
  final String? lastname;
  final String role;
  final String joinedAt;

  const ChatRoomMemberDTO({
    required this.userId,
    required this.email,
    required this.firstname,
    this.lastname,
    required this.role,
    required this.joinedAt,
  });

  factory ChatRoomMemberDTO.fromJson(Map<String, dynamic> json) {
    return ChatRoomMemberDTO(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String?,
      role: json['role'] as String? ?? '',
      joinedAt: json['joined_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'firstname': firstname,
      if (lastname != null) 'lastname': lastname,
      'role': role,
      'joined_at': joinedAt,
    };
  }

  @override
  List<Object?> get props => [
    userId,
    email,
    firstname,
    lastname,
    role,
    joinedAt,
  ];
}
