/// Backend moderation / profanity-filter codes for group chat.
class ChatModeration {
  ChatModeration._();

  static const inappropriateLanguage = 'INAPPROPRIATE_LANGUAGE';

  /// The message being replied to no longer exists — deleted, or never valid.
  static const invalidParentMessage = 'INVALID_PARENT_MESSAGE_ID';

  static bool isInappropriateLanguage(String? code) =>
      code == inappropriateLanguage;

  static bool isInvalidParentMessage(String? code) =>
      code == invalidParentMessage;
}
