import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Whether [senderId] / [senderEmail] identify the signed-in user.
///
/// Two id spaces are in play: `StorageKeys.currentUserId` holds the JWT `sub`
/// claim, while chat `sender_id` is a backend UUID, and `/users/info` returns
/// no id to bridge them. Matching on either the id **or** the email keeps own
/// messages on the right whichever space the deployment uses.
bool isSelfChatMessage({
  required String senderId,
  required String senderEmail,
  String? currentUserId,
  String? currentUserEmail,
}) {
  final id = currentUserId?.trim() ?? '';
  if (id.isNotEmpty && senderId.trim() == id) return true;

  final email = currentUserEmail?.trim().toLowerCase() ?? '';
  if (email.isEmpty) return false;
  return senderEmail.trim().toLowerCase() == email;
}

String? joinChatName(String? firstname, String? lastname) {
  final parts = [
    firstname?.trim() ?? '',
    lastname?.trim() ?? '',
  ].where((part) => part.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' ');
}

/// Message name → email local part → null, in that order. The caller
/// substitutes `group_chat_unknown_sender` for null so the fallback string
/// stays localized.
///
/// [messageName] is `sender_name` off the message. It needs no lookup, so it
/// is right on the first frame — which is why the thread no longer fetches a
/// sender directory at all. The email split remains only for rows written
/// before the API carried a name.
String? chatSenderDisplayName({String? messageName, String? senderEmail}) {
  final fromMessage = messageName?.trim();
  if (fromMessage != null && fromMessage.isNotEmpty) return fromMessage;

  final email = senderEmail?.trim() ?? '';
  if (email.isEmpty) return null;
  final local = email.split('@').first.trim();
  return local.isEmpty ? null : local;
}

/// The value a sender's colour is derived from.
///
/// The backend id is preferred because it never changes; email is the fallback
/// for rows that predate it, and the name only as a last resort. Lower-cased so
/// the same person cannot land on two colours through casing alone.
String chatSenderSeed({String? senderId, String? senderEmail, String? name}) {
  for (final candidate in [senderId, senderEmail, name]) {
    final value = candidate?.trim().toLowerCase() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

/// A participant's colour, stable for the life of that seed.
///
/// FNV-1a rather than [String.hashCode]: the hash has to give the same person
/// the same colour on every device and every launch, and `hashCode` carries no
/// such guarantee across platforms or SDK versions.
Color chatSenderColor({required String seed, required bool onDark}) {
  final palette =
      onDark ? AppColors.chatSenderColorsDark : AppColors.chatSenderColors;
  if (seed.isEmpty) return palette.first;

  var hash = 0x811c9dc5;
  for (final unit in seed.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return palette[hash % palette.length];
}

/// Up to two initials for the avatar fallback.
String chatSenderInitials(String? displayName) {
  final value = displayName?.trim() ?? '';
  if (value.isEmpty) return '?';
  final words = value.split(RegExp(r'[\s._-]+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  final letters = words.take(2).map((w) => w.characters.first).join();
  return letters.toUpperCase();
}
