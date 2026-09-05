import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/group_chat/chat_moderation.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';

/// Shared code for REST 400 and WS `type: error` frames.
String? chatSendErrorCode(Object error) {
  return switch (error) {
    ValidationFailure(:final code) => code,
    ValidationException(:final code) => code,
    ChatLiveError(:final code) => code,
    _ => null,
  };
}

enum ChatSendErrorKind { inappropriate, notAMember, invalidParent, generic }

/// Classifies send failures so REST 403 and WS errors share the same copy.
ChatSendErrorKind chatSendErrorKind(Object error) {
  final code = chatSendErrorCode(error);
  if (ChatModeration.isInappropriateLanguage(code)) {
    return ChatSendErrorKind.inappropriate;
  }
  if (ChatModeration.isInvalidParentMessage(code)) {
    return ChatSendErrorKind.invalidParent;
  }
  if (error is AuthorizationFailure || error is AuthorizationException) {
    return ChatSendErrorKind.notAMember;
  }
  return ChatSendErrorKind.generic;
}

String chatSendErrorMessage(AppLocalizations l10n, Object error) {
  return switch (chatSendErrorKind(error)) {
    ChatSendErrorKind.inappropriate => l10n.group_chat_inappropriate,
    ChatSendErrorKind.notAMember => l10n.group_chat_not_a_member,
    ChatSendErrorKind.invalidParent => l10n.group_chat_reply_parent_gone,
    ChatSendErrorKind.generic => switch (error) {
      Failure(:final message) => message,
      ChatLiveError(:final message) => message,
      Exception() => error.toString(),
      _ => error.toString(),
    },
  };
}

/// Surfaces send failures. Profanity and 403 use dedicated l10n strings.
void presentChatSendError(BuildContext context, Object error) {
  showChatSendError(ScaffoldMessenger.of(context), context.l10n, error);
}

/// The same copy, for callers that resolved the messenger and localizations
/// while their element was still active.
///
/// A socket frame can land after a route pop but before the element unmounts.
/// `ScaffoldMessenger.of` and `context.l10n` are both ancestor lookups, and in
/// that window they throw "Looking up a deactivated widget's ancestor is
/// unsafe" — which lands mid-frame and replaces the thread with a red error
/// box rather than showing a snack bar.
void showChatSendError(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  Object error,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(chatSendErrorMessage(l10n, error))));
}
