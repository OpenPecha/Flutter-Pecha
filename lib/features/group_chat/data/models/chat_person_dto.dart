import 'package:equatable/equatable.dart';

/// A person in a group, from `GET /chat/groups/{group_id}/people`.
///
/// The endpoint exists for DM candidates, but it is the only chat surface that
/// returns `avatar_url` alongside `user_id`, so the thread reads it purely to
/// put faces on other people's bubbles.
class ChatPersonDTO extends Equatable {
  final String userId;
  final String email;
  final String firstname;
  final String? lastname;
  final String? avatarUrl;

  const ChatPersonDTO({
    required this.userId,
    required this.email,
    required this.firstname,
    this.lastname,
    this.avatarUrl,
  });

  factory ChatPersonDTO.fromJson(Map<String, dynamic> json) {
    return ChatPersonDTO(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'firstname': firstname,
      if (lastname != null) 'lastname': lastname,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [userId, email, firstname, lastname, avatarUrl];
}
