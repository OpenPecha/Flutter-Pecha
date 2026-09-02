import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
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
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_swipe_to_reply.dart';
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
    required this.onReply,
  });

  final String roomId;
  final String groupId;
  final String currentUserId;

  /// Starts a reply in the composer, which the screen owns.
  final ValueChanged<ChatMessageDTO> onReply;

  @override
  ConsumerState<GroupChatThread> createState() => _GroupChatThreadState();
}

class _GroupChatThreadState extends ConsumerState<GroupChatThread> {
  final _scrollController = ScrollController();

  /// One key per message so the long-press menu can measure the row it lifts.
  final _rowKeys = <String, GlobalKey>{};

  /// The newest message already seen, so an arrival can be told from a rebuild.
  String? _newestId;

  /// How close to the newest message counts as "following the conversation".
  /// Reversed list, so offset 0 is the bottom.
  static const double _followThreshold = 120;

  /// Bounds the walk towards an off-screen quote, so a parent that never
  /// materialises cannot spin.
  static const int _maxScrollHops = 20;

  /// Bounds how far back the thread will page to find a quoted original.
  static const int _maxLoadHops = 12;

  /// Offset past which the jump-to-latest button appears.
  static const double _jumpButtonThreshold = 400;

  bool _showJumpToLatest = false;

  /// The message a quote jumped to, tinted briefly so the eye can find it in
  /// a wall of text. Long enough to notice, short enough not to look selected.
  static const Duration _highlightDuration = Duration(milliseconds: 900);
  String? _highlightedId;
  Timer? _highlightTimer;

  /// Distance from the reversed end at which the next page is requested.
  static const double _loadMoreThreshold = 320;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _flashHighlight(String messageId) {
    _highlightTimer?.cancel();
    setState(() => _highlightedId = messageId);
    _highlightTimer = Timer(_highlightDuration, () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(groupChatThreadProvider(widget.roomId).notifier).loadMore();
    }

    final shouldShow = position.pixels > _jumpButtonThreshold;
    if (shouldShow != _showJumpToLatest) {
      setState(() => _showJumpToLatest = shouldShow);
    }
  }

  GlobalKey _rowKey(String messageId) =>
      _rowKeys.putIfAbsent(messageId, GlobalKey.new);

  bool get _isNearBottom =>
      !_scrollController.hasClients ||
      _scrollController.offset <= _followThreshold;

  /// Brings the newest message into view. The list is reversed, so the bottom
  /// is offset zero.
  void _scrollToNewest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  /// Follows a newly arrived message.
  ///
  /// Own messages always scroll — you should see what you just sent, wherever
  /// you were reading. Someone else's only scrolls when already near the
  /// bottom, so a message arriving does not yank you out of older history you
  /// are reading.
  void _onNewestChanged(ChatMessageDTO newest, bool isMine) {
    final follow = isMine || _isNearBottom;
    _newestId = newest.id;
    if (!follow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToNewest();
    });
  }

  /// Scrolls to a quoted original.
  ///
  /// `ListView.builder` only keeps rows near the viewport alive, so a parent
  /// that is off screen has no context to scroll to yet — which is why tapping
  /// a quote used to work for nearby originals and do nothing for distant
  /// ones. Older messages sit at a larger offset in this reversed list, so the
  /// search walks that way a viewport at a time, building rows as it goes,
  /// until the target materialises and `ensureVisible` can place it exactly.
  Future<void> _scrollToMessage(String messageId) async {
    if (await _ensureMessageVisible(messageId)) return;

    // Older than the loaded window: page back until it appears, so a quote
    // still reaches its original however far up the thread it sits.
    if (!await _loadUntilPresent(messageId)) return;

    for (var attempt = 0; attempt < _maxScrollHops; attempt++) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final next = (position.pixels + position.viewportDimension * 0.85).clamp(
        0.0,
        position.maxScrollExtent,
      );
      // Already at the oldest loaded row: nowhere further to look.
      if (next <= position.pixels) return;

      _scrollController.jumpTo(next);
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
      if (await _ensureMessageVisible(messageId)) return;
    }
  }

  /// Pages back until [messageId] is in the loaded window.
  ///
  /// Returns false when the thread runs out of history first, or when the walk
  /// is bounded out — a quote whose original was never in this room cannot be
  /// found by paging forever.
  Future<bool> _loadUntilPresent(String messageId) async {
    final provider = groupChatThreadProvider(widget.roomId);
    for (var attempt = 0; attempt < _maxLoadHops; attempt++) {
      final state = ref.read(provider);
      if (state.messages.any((message) => message.id == messageId)) return true;
      if (!state.hasMore) return false;

      await ref.read(provider.notifier).loadMore();
      if (!mounted) return false;
      // `loadMore` returns immediately while another page is already in
      // flight, so yield a frame rather than spinning through the budget.
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return false;
    }
    return ref
        .read(provider)
        .messages
        .any((message) => message.id == messageId);
  }

  /// Places [messageId] in view when its row is currently built.
  Future<bool> _ensureMessageVisible(String messageId) async {
    final target = _rowKeys[messageId]?.currentContext;
    if (target == null) return false;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.3,
    );
    if (mounted) _flashHighlight(messageId);
    return true;
  }

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
    final user = ref.read(userProvider).user;
    showChatReactionsSheet(
      context,
      reactions: message.reactions,
      currentUserEmail: user?.email,
      // `ChatMessageReactionUserDTO` carries no avatar, but every loaded
      // message does — and reactors are almost always people who have posted
      // in the thread. Free lookup, no request.
      avatarUrls: _avatarsBySenderId(),
      selfAvatarUrl: user?.avatarUrl,
      onToggle: (emoji) => _toggleReaction(message.id, emoji),
      onAddReaction: () => showChatEmojiPicker(context),
    );
  }

  Map<String, String> _avatarsBySenderId() {
    final messages = ref.read(groupChatThreadProvider(widget.roomId)).messages;
    return {
      for (final message in messages)
        if ((message.senderAvatarUrl ?? '').isNotEmpty)
          message.senderId: message.senderAvatarUrl!,
    };
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.group_chat_copied)));
      case ChatMessageAction.reply:
        widget.onReply(message);
      case ChatMessageAction.report:
      case ChatMessageAction.delete:
        // Wired by tasks 5 and 6.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupChatThreadProvider(widget.roomId));
    final notifier = ref.read(groupChatThreadProvider(widget.roomId).notifier);
    final user = ref.watch(userProvider).user;

    ref.listen(groupChatThreadProvider(widget.roomId), (_, next) {
      if (next.messages.isEmpty) return;
      final newest = next.messages.first;
      // Only an arrival counts; `skip`, loading flags and reaction edits all
      // rebuild without changing which message is newest.
      if (newest.id == _newestId) return;
      _onNewestChanged(
        newest,
        isSelfChatMessage(
          senderId: newest.senderId,
          senderEmail: newest.senderEmail,
          currentUserId: widget.currentUserId,
          currentUserEmail: ref.read(userProvider).user?.email,
        ),
      );
    });

    if (!state.hasLoaded && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.messages.isEmpty) {
      return _dismissKeyboardOnTap(_ThreadError(onRetry: notifier.retry));
    }

    if (state.messages.isEmpty) {
      return _dismissKeyboardOnTap(const GroupChatEmptyState());
    }

    final rows = buildChatThreadRows(state.messages);

    // No keyboard inset here. The composer sits in the same Column and grows
    // by the inset itself, which already shrinks this Expanded to the space
    // above the field — adding it again would double the gap under the newest
    // message.
    return _dismissKeyboardOnTap(
      Stack(
        children: [
          _buildList(state, rows, user),
          if (_showJumpToLatest)
            Positioned(
              right: 16,
              bottom: 12,
              child: _JumpToLatestButton(onTap: _scrollToNewest),
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    GroupChatThreadState state,
    List<ChatThreadRow> rows,
    User? user,
  ) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      // Dragging the thread closes the keyboard, as every chat app does. On
      // iOS this is the primary way out — there is no system back button to
      // dismiss it, which is why the keyboard felt stuck there and not on
      // Android.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                selfAvatarUrl: user?.avatarUrl,
                selfDisplayName: joinChatName(user?.firstName, user?.lastName),
                onLongPress: onLongPress,
                isHighlighted: message.id == _highlightedId,
                onShowReactions: () => _showReactions(message),
                onTapQuote:
                    message.parent == null
                        ? null
                        : () => _scrollToMessage(message.parent!.id),
              );
            }

            // The menu re-renders the row over its own blurred backdrop, so it
            // gets a copy without the long-press handler.
            final lifted = bubble();
            return KeyedSubtree(
              key: _rowKey(message.id),
              // Swipe and long-press reach the same reply path, so the two
              // gestures cannot disagree about what a reply means.
              child: GroupChatSwipeToReply(
                onReply: () => widget.onReply(message),
                child: bubble(onLongPress: () => _openMenu(message, lifted)),
              ),
            );
        }
      },
    );
  }

  /// Taps that no child claims fall through to here and drop focus, so tapping
  /// the thread closes the keyboard.
  Widget _dismissKeyboardOnTap(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}

/// Jumps straight back to the newest message. Appears only once the thread
/// has been scrolled away from the bottom, so it never covers a message the
/// user is already reading at the end of the conversation.
class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            AppAssets.caretDoubleDown,
            size: 20,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
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
