import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_person_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_room_member_dto.dart';

/// Display identity for a message sender.
///
/// `ChatMessageDTO` carries only `sender_id` and `sender_email`, so names and
/// avatars are joined in from two endpoints: room members supply the name,
/// group people supply `avatar_url`. Either half may be missing.
class ChatSender extends Equatable {
  final String userId;
  final String? name;
  final String? email;
  final String? avatarUrl;

  const ChatSender({
    required this.userId,
    this.name,
    this.email,
    this.avatarUrl,
  });

  ChatSender mergeWith(ChatSender other) {
    return ChatSender(
      userId: userId,
      name: _firstNonEmpty(name, other.name),
      email: _firstNonEmpty(email, other.email),
      avatarUrl: _firstNonEmpty(avatarUrl, other.avatarUrl),
    );
  }

  @override
  List<Object?> get props => [userId, name, email, avatarUrl];
}

/// Builds the `user_id` → sender lookup the thread renders from. Either list
/// may be empty when its request failed; the merge is best-effort.
Map<String, ChatSender> buildChatSenderDirectory({
  List<ChatRoomMemberDTO> members = const [],
  List<ChatPersonDTO> people = const [],
}) {
  final directory = <String, ChatSender>{};

  void add(ChatSender sender) {
    if (sender.userId.isEmpty) return;
    final existing = directory[sender.userId];
    directory[sender.userId] =
        existing == null ? sender : existing.mergeWith(sender);
  }

  for (final member in members) {
    add(
      ChatSender(
        userId: member.userId,
        name: joinChatName(member.firstname, member.lastname),
        email: member.email,
      ),
    );
  }
  for (final person in people) {
    add(
      ChatSender(
        userId: person.userId,
        name: joinChatName(person.firstname, person.lastname),
        email: person.email,
        avatarUrl: person.avatarUrl,
      ),
    );
  }

  return directory;
}

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

/// Directory name → email local part → null, in that order. The caller
/// substitutes `group_chat_unknown_sender` for null so the fallback string
/// stays localized.
String? chatSenderDisplayName({ChatSender? sender, String? senderEmail}) {
  final name = sender?.name?.trim();
  if (name != null && name.isNotEmpty) return name;

  final email = (sender?.email ?? senderEmail ?? '').trim();
  if (email.isEmpty) return null;
  final local = email.split('@').first.trim();
  return local.isEmpty ? null : local;
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

String? _firstNonEmpty(String? a, String? b) {
  if (a != null && a.trim().isNotEmpty) return a;
  if (b != null && b.trim().isNotEmpty) return b;
  return null;
}
