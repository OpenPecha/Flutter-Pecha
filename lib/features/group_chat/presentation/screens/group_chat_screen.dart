import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_reaction_dto.dart';
import 'package:flutter_pecha/features/group_chat/domain/usecases/resolve_group_chat_room.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_empty_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_error_state.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_header.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_thread.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Where the screen stands on the room that backs this group.
///
/// [absent] is a member with nothing to read yet, not a member who still has
/// to opt in: the composer is live in every state but [resolving].
enum _RoomState { resolving, absent, joined, unavailable }

/// Member-gated chat shell. Group membership alone grants read and send.
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with WidgetsBindingObserver {
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();
  ChatLiveClient? _live;
  StreamSubscription<ChatLiveEvent>? _liveSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _hadLiveSession = false;
  bool _connectingLive = false;
  bool _redirecting = false;
  bool _sending = false;
  bool _resolvingRoom = false;
  _RoomState _roomState = _RoomState.resolving;
  String? _roomId;
  String _currentUserId = '';

  /// True once the group has a room session worth holding a socket open for.
  /// [_RoomState.absent] counts: the socket is group-scoped, so it reports the
  /// room the moment another member creates it.
  bool get _hasRoomSession =>
      _roomState == _RoomState.joined || _roomState == _RoomState.absent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    unawaited(_tearDownLive());
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasRoomSession) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _reconnectTimer?.cancel();
        unawaited(_tearDownLive());
      case AppLifecycleState.resumed:
        unawaited(_ensureLiveConnected());
        unawaited(_markRoomRead());
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _tearDownLive() async {
    await _liveSub?.cancel();
    _liveSub = null;
    await _live?.dispose();
    _live = null;
  }

  String get _profilePath => '/home/group/${widget.groupId}';

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_profilePath);
    }
  }

  /// Leaves the chat once group membership is denied or the session is not
  /// eligible. [notAMember] is reserved for a confirmed non-follower.
  void _leaveChat({required bool toHome, bool notAMember = false}) {
    if (_redirecting) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (notAMember) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.group_chat_not_a_member)),
        );
      }
      if (toHome) {
        context.go(AppRoutes.home);
        return;
      }
      _goBack();
    });
  }

  Future<String> _userId() async {
    if (_currentUserId.isNotEmpty) return _currentUserId;
    final userId =
        await ref
            .read(storageServiceProvider)
            .get<String>(StorageKeys.currentUserId) ??
        '';
    _currentUserId = userId;
    return userId;
  }

  /// Resolves the room once per screen. Runs again only through
  /// [_retryResolveRoom] after a failed lookup.
  Future<void> _resolveRoom() async {
    if (_resolvingRoom) return;
    _resolvingRoom = true;
    final userId = await _userId();
    if (!mounted) return;
    final lookup = await ref.read(resolveGroupChatRoomProvider)(
      userId: userId,
      groupId: widget.groupId,
    );
    if (!mounted) return;
    switch (lookup) {
      case GroupChatRoomFound(roomId: final roomId):
        setState(() {
          _roomId = roomId;
          _roomState = _RoomState.joined;
        });
        await _ensureLiveConnected();
        await _markRoomRead();
      case GroupChatRoomMissing():
        setState(() => _roomState = _RoomState.absent);
        await _ensureLiveConnected();
      case GroupChatRoomUnavailable():
        setState(() => _roomState = _RoomState.unavailable);
    }
  }

  void _retryResolveRoom() {
    setState(() => _roomState = _RoomState.resolving);
    _resolvingRoom = false;
    unawaited(_resolveRoom());
  }

  /// Connects the socket. Never throws: every caller — the send flow, the
  /// lifecycle observer and the reconnect timer itself — invokes this without
  /// an error handler, so a failure here must degrade to a retry rather than
  /// escape as an unhandled async error.
  Future<void> _ensureLiveConnected() async {
    if (_live != null || _connectingLive || !_hasRoomSession) return;
    // Set synchronously, before the first await, so a second caller racing in
    // before token retrieval resolves sees this and backs off instead of
    // opening a second socket that would silently orphan this one.
    _connectingLive = true;

    final String? token;
    try {
      token = await ref.read(authServiceProvider).getValidAccessToken();
    } catch (_) {
      // A renewal can fail transiently; back off and try the whole thing again
      // instead of leaving live updates silently disconnected.
      _connectingLive = false;
      _scheduleReconnect();
      return;
    }
    if (!mounted || token == null) {
      _connectingLive = false;
      return;
    }

    final uri = ChatLiveClient.liveUri(
      restBaseUrl: ref.read(apiConfigProvider).baseUrl,
      token: token,
      groupId: widget.groupId,
      roomId: _roomId,
    );
    final client = ChatLiveClient();
    _live = client;
    _connectingLive = false;
    final reconnected = _hadLiveSession;
    _hadLiveSession = true;

    try {
      _liveSub = client
          .connect(uri)
          .listen(
            _onLiveEvent,
            onError: (_) => _scheduleReconnect(),
            onDone: _scheduleReconnect,
            cancelOnError: true,
          );
    } catch (_) {
      // Clear the client first: the guard above treats a non-null _live as
      // "already connected" and would wedge live updates for good.
      _live = null;
      _scheduleReconnect();
      return;
    }

    // Anything missed while the socket was down is merged in by id.
    if (reconnected) await _refreshThread();
  }

  void _onLiveEvent(ChatLiveEvent event) {
    if (!mounted) return;
    // A frame on a fresh socket means the connection is healthy again.
    _reconnectAttempt = 0;

    switch (event) {
      case ChatLiveRoomInfo(roomId: final roomId):
        _adoptRoomId(roomId);
      case ChatLiveMessageCreated(message: final json):
        _onMessageCreated(json);
      case ChatLiveError():
        presentChatSendError(context, event);
      case ChatLiveReactionsUpdated(
        messageId: final messageId,
        reactions: final raw,
      ):
        _onReactionsUpdated(messageId, raw);
      case ChatLiveTyping():
      case ChatLivePresence():
      case ChatLiveUnknown():
        break;
    }
  }

  /// Adopts a room the server reports over the socket — covers a room someone
  /// else created while this screen was open.
  void _adoptRoomId(String roomId) {
    if (roomId.isEmpty || _roomId == roomId) return;
    setState(() {
      _roomId = roomId;
      _roomState = _RoomState.joined;
    });
    unawaited(_persistRoomId(roomId));
    unawaited(_markRoomRead());
  }

  void _onMessageCreated(Map<String, dynamic> json) {
    if (json.isEmpty) return;
    final message = ChatMessageDTO.fromJson(json);
    if (message.id.isEmpty || message.roomId.isEmpty) return;
    // The first message in a group creates its room, and this frame can be the
    // first mention of it when the sender was someone else.
    _adoptRoomId(message.roomId);
    if (_roomId != message.roomId) return;
    ref
        .read(groupChatThreadProvider(message.roomId).notifier)
        .appendLive(message);
    unawaited(_markRoomRead());
  }

  /// Applies a reaction broadcast. The payload is shared by every member, so
  /// `reacted_by_me` on it is not viewer-specific — the notifier re-derives
  /// own state from the identity we hold.
  void _onReactionsUpdated(String messageId, List<dynamic> raw) {
    final roomId = _roomId;
    if (roomId == null || messageId.isEmpty) return;
    ref
        .read(groupChatThreadProvider(roomId).notifier)
        .replaceReactions(
          messageId,
          raw
              .whereType<Map<String, dynamic>>()
              .map(ChatMessageReactionDTO.fromJson)
              .toList(),
          currentUserId: _currentUserId,
          currentUserEmail: ref.read(userProvider).user?.email,
        );
  }

  Future<void> _refreshThread() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await ref.read(groupChatThreadProvider(roomId).notifier).refreshLatest();
  }

  void _scheduleReconnect() {
    if (!mounted || !_hasRoomSession) return;
    _reconnectTimer?.cancel();
    _reconnectAttempt++;
    _reconnectTimer = Timer(chatReconnectDelay(_reconnectAttempt), () async {
      if (!mounted) return;
      await _tearDownLive();
      await _ensureLiveConnected();
    });
  }

  /// Best-effort: a failed read receipt never surfaces to the user.
  Future<void> _markRoomRead() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await ref.read(groupChatRepositoryProvider).markRoomRead(roomId);
  }

  Future<void> _persistRoomId(String roomId) async {
    try {
      final userId = await _userId();
      await ref
          .read(groupChatRoomCacheProvider)
          .write(userId: userId, groupId: widget.groupId, roomId: roomId);
    } catch (_) {
      // Cache is best-effort; join is already committed on the server.
    }
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(groupChatRepositoryProvider)
          .sendGroupMessage(widget.groupId, body: body);
      if (!mounted) return;
      await result.fold(
        (failure) async {
          setState(() => _sending = false);
          presentChatSendError(context, failure);
        },
        (message) async {
          await _persistRoomId(message.roomId);
          if (!mounted) return;
          _bodyController.clear();
          setState(() {
            _sending = false;
            _roomId = message.roomId;
            _roomState = _RoomState.joined;
          });
          // The POST returns the created message, so it is inserted directly
          // and the `message_created` echo dedupes against it by id.
          ref
              .read(groupChatThreadProvider(message.roomId).notifier)
              .appendLive(message);
          await _ensureLiveConnected();
        },
      );
    } finally {
      if (mounted && _sending) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (auth.isGuest || !auth.isLoggedIn) {
      _leaveChat(toHome: true);
      return _buildShell(context, body: const SizedBox.shrink());
    }

    final profileAsync = ref.watch(groupProfileProvider(widget.groupId));

    return profileAsync.when(
      loading: () => _buildShell(context, body: _buildLoading()),
      error: (_, _) {
        _leaveChat(toHome: false);
        return _buildShell(context, body: const SizedBox.shrink());
      },
      data: (either) {
        return either.fold((_) {
          _leaveChat(toHome: false);
          return _buildShell(context, body: const SizedBox.shrink());
        }, (profile) => _buildMemberGate(context, profile));
      },
    );
  }

  Widget _buildMemberGate(BuildContext context, GroupProfile profile) {
    final followState = ref.watch(
      groupFollowProvider(
        GroupFollowKey(groupId: profile.id, groupType: profile.groupType),
      ),
    );

    // A failed re-check is not a confirmed non-member — it means the cause is
    // unknown, so fall back to the last known-good state instead of evicting
    // someone who is very likely still a member.
    final isMember = switch (followState) {
      GroupFollowSuccess(isFollowing: final following) => following,
      GroupFollowLoading() => profile.isFollowing,
      GroupFollowFailure() => profile.isFollowing,
    };
    final confirmedNonMember =
        followState is GroupFollowSuccess && !followState.isFollowing;

    if (followState is GroupFollowLoading && !profile.isFollowing) {
      return _buildShell(context, profile: profile, body: _buildLoading());
    }

    if (!isMember) {
      _leaveChat(toHome: false, notAMember: confirmedNonMember);
      return _buildShell(
        context,
        profile: profile,
        body: const SizedBox.shrink(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_resolveRoom());
    });

    final roomId = _roomId;

    return _buildShell(
      context,
      profile: profile,
      body: switch (_roomState) {
        _RoomState.resolving => _buildLoading(),
        _RoomState.absent => const GroupChatEmptyState(),
        _RoomState.unavailable => GroupChatErrorState(
          onRetry: _retryResolveRoom,
        ),
        _RoomState.joined =>
          roomId == null
              ? _buildLoading()
              : GroupChatThread(
                roomId: roomId,
                groupId: widget.groupId,
                currentUserId: _currentUserId,
              ),
      },
      // A confirmed member may always write: a lookup that found no room, or
      // failed outright, still sends — the POST creates the room by group id.
      showComposer: _roomState != _RoomState.resolving,
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required Widget body,
    GroupProfile? profile,
    bool showComposer = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider).user;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GroupChatHeader(isDark: isDark, onBack: _goBack, profile: profile),
            Expanded(child: body),
            if (showComposer)
              GroupChatComposer(
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                hintText: context.l10n.group_chat_message_hint,
                isSending: _sending,
                onSubmit: _send,
                avatarUrl: user?.avatarUrl,
                displayName:
                    joinChatName(user?.firstName, user?.lastName) ??
                    user?.email,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }
}
