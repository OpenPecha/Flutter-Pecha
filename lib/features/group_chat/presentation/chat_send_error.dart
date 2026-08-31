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

enum ChatSendErrorKind { inappropriate, notAMember, generic }

/// Classifies send failures so REST 403 and WS errors share the same copy.
ChatSendErrorKind chatSendErrorKind(Object error) {
  if (ChatModeration.isInappropriateLanguage(chatSendErrorCode(error))) {
    return ChatSendErrorKind.inappropriate;
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
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(chatSendErrorMessage(context.l10n, error))),
    );
}
