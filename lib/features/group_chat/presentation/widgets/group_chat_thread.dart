import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_thread_rows.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_date_separator.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_empty_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_message_bubble.dart';
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
