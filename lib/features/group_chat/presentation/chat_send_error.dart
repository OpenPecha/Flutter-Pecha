import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/exceptions.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
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

/// Surfaces send failures. Profanity always uses [group_chat_inappropriate].
void presentChatSendError(BuildContext context, Object error) {
  final l10n = context.l10n;
  final message =
      ChatModeration.isInappropriateLanguage(chatSendErrorCode(error))
          ? l10n.group_chat_inappropriate
          : switch (error) {
            Failure(:final message) => message,
            ChatLiveError(:final message) => message,
            Exception() => error.toString(),
            _ => error.toString(),
          };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
