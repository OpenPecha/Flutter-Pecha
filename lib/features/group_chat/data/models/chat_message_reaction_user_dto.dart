import 'package:equatable/equatable.dart';

class ChatMessageReactionUserDTO extends Equatable {
  final String userId;
  final String? email;
  final String? name;

  const ChatMessageReactionUserDTO({
    required this.userId,
    this.email,
    this.name,
  });

  factory ChatMessageReactionUserDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageReactionUserDTO(
      userId: json['user_id'] as String? ?? '',
      email: json['email'] as String?,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
    };
  }

  @override
  List<Object?> get props => [userId, email, name];
}
