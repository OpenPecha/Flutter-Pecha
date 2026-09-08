import 'package:flutter_pecha/features/group_profile/domain/entities/group_notification_preferences.dart';

/// Wire shape of `GET/PUT /author/groups/{id}/notification-preferences` and
/// of the `my_notification_preferences` object on the group detail response:
///
/// ```json
/// { "chat": true, "content": false }
/// ```
///
/// A missing key falls back to the backend default (`true`) so a partial
/// object never reads as "muted".
class GroupNotificationPreferencesModel {
  final bool chat;
  final bool content;

  const GroupNotificationPreferencesModel({
    required this.chat,
    required this.content,
  });

  factory GroupNotificationPreferencesModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GroupNotificationPreferencesModel(
      chat: json['chat'] as bool? ?? true,
      content: json['content'] as bool? ?? true,
    );
  }

  /// Body for the PUT request. Only the keys the caller passes are sent so
  /// one toggle can change without clobbering the other from a stale value.
  static Map<String, dynamic> toRequestJson({bool? chat, bool? content}) {
    return {
      if (chat != null) 'chat': chat,
      if (content != null) 'content': content,
    };
  }

  GroupNotificationPreferences toEntity() {
    return GroupNotificationPreferences(chat: chat, content: content);
  }
}
