import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reactions.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_date_separator.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_emoji_picker.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_empty_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_bubble.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_menu.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_reactions_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The message list for a joined room.
///
/// Reversed so index 0 is the newest message at the bottom: "load older" is a
/// tail append and the newest row stays pinned above the keyboard for free.
class GroupChatThread extends ConsumerStatefulWidget {
  const GroupChatThread({
    super.key,
    required this.roomId,
    required this.groupId,
    required this.currentUserId,
  });

  final String roomId;
  final String groupId;
  final String currentUserId;

  @override
  ConsumerState<GroupChatThread> createState() => _GroupChatThreadState();
}

class _GroupChatThreadState extends ConsumerState<GroupChatThread> {
  final _scrollController = ScrollController();

  /// One key per message so the long-press menu can measure the row it lifts.
  final _rowKeys = <String, GlobalKey>{};

  /// Distance from the reversed end at which the next page is requested.
  static const double _loadMoreThreshold = 320;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(groupChatThreadProvider(widget.roomId).notifier).loadMore();
    }
  }

  GlobalKey _rowKey(String messageId) =>
      _rowKeys.putIfAbsent(messageId, GlobalKey.new);

  Map<String, ChatSender> get _directory =>
      ref
          .read(
            groupChatSenderDirectoryProvider(
              ChatDirectoryKey(
                roomId: widget.roomId,
                groupId: widget.groupId,
              ),
            ),
          )
          .valueOrNull ??
      const <String, ChatSender>{};

  Future<void> _toggleReaction(String messageId, String emoji) async {
    final failure = await ref
        .read(groupChatThreadProvider(widget.roomId).notifier)
        .toggleReaction(
          messageId,
          emoji,
          roomIdForCall: widget.roomId,
          currentUserId: widget.currentUserId,
          currentUserEmail: ref.read(userProvider).user?.email,
        );
    if (!mounted || failure == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.group_chat_reaction_failed)),
    );
  }

  void _showReactions(ChatMessageDTO message) {
    if (message.reactions.isEmpty) return;
    showChatReactionsSheet(
      context,
      reactions: message.reactions,
      directory: _directory,
      currentUserEmail: ref.read(userProvider).user?.email,
      onToggle: (emoji) => _toggleReaction(message.id, emoji),
      onAddReaction: () => showChatEmojiPicker(context),
    );
  }

  Future<void> _openMenu(ChatMessageDTO message, Widget row) async {
    final renderObject =
        _rowKeys[message.id]?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final anchor = renderObject.localToGlobal(Offset.zero) & renderObject.size;

    final result = await showChatMessageMenu(
      context,
      anchor: anchor,
      message: row,
      myEmoji: currentChatReactionEmoji(message.reactions),
      canDelete: false, // Delete lands with task 6.
    );
    if (!mounted || result == null) return;

    switch (result) {
      case ChatMessageReact(emoji: final emoji):
        await _toggleReaction(message.id, emoji);
      case ChatMessageMoreEmoji():
        final picked = await showChatEmojiPicker(context);
        if (!mounted || picked == null) return;
        await _toggleReaction(message.id, picked);
      case ChatMessageActionPicked(action: final action):
        await _onAction(action, message);
    }
  }

  Future<void> _onAction(
    ChatMessageAction action,
    ChatMessageDTO message,
  ) async {
    switch (action) {
      case ChatMessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.body));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.group_chat_copied)),
        );
      case ChatMessageAction.reply:
      case ChatMessageAction.report:
      case ChatMessageAction.delete:
        // Wired by tasks 5 and 6.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupChatThreadProvider(widget.roomId));
    final notifier = ref.read(
      groupChatThreadProvider(widget.roomId).notifier,
    );
    final user = ref.watch(userProvider).user;
    final directory =
        ref
            .watch(
              groupChatSenderDirectoryProvider(
                ChatDirectoryKey(
                  roomId: widget.roomId,
                  groupId: widget.groupId,
                ),
              ),
            )
            .valueOrNull ??
        const <String, ChatSender>{};

    if (!state.hasLoaded && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return _ThreadError(onRetry: notifier.retry);
    }

    if (state.messages.isEmpty) return const GroupChatEmptyState();

    final rows = buildChatThreadRows(state.messages);

    // No keyboard inset here. The composer sits in the same Column and grows
    // by the inset itself, which already shrinks this Expanded to the space
    // above the field — adding it again would double the gap under the newest
    // message.
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: rows.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= rows.length) return const _LoadingMoreFooter();

        final row = rows[index];
        switch (row) {
          case ChatDateRow(day: final day):
            return GroupChatDateSeparator(day: day);
          case ChatMessageRow(
            message: final message,
            isRunStart: final isRunStart,
          ):
            GroupChatMessageBubble bubble({VoidCallback? onLongPress}) {
              return GroupChatMessageBubble(
                message: message,
                isSelf: isSelfChatMessage(
                  senderId: message.senderId,
                  senderEmail: message.senderEmail,
                  currentUserId: widget.currentUserId,
                  currentUserEmail: user?.email,
                ),
                isRunStart: isRunStart,
                sender: directory[message.senderId],
                selfAvatarUrl: user?.avatarUrl,
                selfDisplayName: joinChatName(user?.firstName, user?.lastName),
                onLongPress: onLongPress,
                onShowReactions: () => _showReactions(message),
              );
            }

            // The menu re-renders the row over its own blurred backdrop, so it
            // gets a copy without the long-press handler.
            final lifted = bubble();
            return KeyedSubtree(
              key: _rowKey(message.id),
              child: bubble(onLongPress: () => _openMenu(message, lifted)),
            );
        }
      },
    );
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.group_chat_load_failed,
              textAlign: TextAlign.center,
              strutStyle: context.tibetanStrutStyle(14),
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.group_chat_retry),
            ),
          ],
        ),
      ),
    );
  }
}
