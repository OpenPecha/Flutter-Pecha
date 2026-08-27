/// Backend moderation / profanity-filter codes for group chat.
class ChatModeration {
  ChatModeration._();

  static const inappropriateLanguage = 'INAPPROPRIATE_LANGUAGE';

  static bool isInappropriateLanguage(String? code) =>
      code == inappropriateLanguage;
}
