import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_thread_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_reconnect_backoff.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_header.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_join_banner.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_thread.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _JoinState { checking, preJoin, joined }

/// Member-gated chat shell. Pre-join until the first successful send.
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
  bool _redirecting = false;
  bool _sending = false;
  bool _bootstrapped = false;
  bool _composerUnlocked = false;
  _JoinState _joinState = _JoinState.checking;
  String? _roomId;
  String _currentUserId = '';

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
    if (_joinState != _JoinState.joined) return;
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

  Future<void> _bootstrapJoinState() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    final userId = await _userId();
    if (!mounted) return;
    final cache = ref.read(groupChatRoomCacheProvider);
    final cached = await cache.read(userId: userId, groupId: widget.groupId);
    if (!mounted) return;
    if (cached == null) {
      setState(() => _joinState = _JoinState.preJoin);
      return;
    }

    final result = await ref.read(groupChatRepositoryProvider).getRoom(cached);
    if (!mounted) return;
    await result.fold(
      (failure) async {
        if (failure is NotFoundFailure) {
          await cache.clear(userId: userId, groupId: widget.groupId);
        }
        if (!mounted) return;
        setState(() => _joinState = _JoinState.preJoin);
      },
      (room) async {
        setState(() {
          _roomId = room.id;
          _joinState = _JoinState.joined;
          _composerUnlocked = true;
        });
        await _ensureLiveConnected();
        await _markRoomRead();
      },
    );
  }

  /// Connects the socket. Never throws: every caller — the send flow, the
  /// lifecycle observer and the reconnect timer itself — invokes this without
  /// an error handler, so a failure here must degrade to a retry rather than
  /// escape as an unhandled async error.
  Future<void> _ensureLiveConnected() async {
    if (_live != null || _joinState != _JoinState.joined) return;

    final String? token;
    try {
      token = await ref.read(authServiceProvider).getValidAccessToken();
    } catch (_) {
      // A renewal can fail transiently; back off and try the whole thing again
      // instead of leaving live updates silently disconnected.
      _scheduleReconnect();
      return;
    }
    if (!mounted || token == null) return;

    final uri = ChatLiveClient.liveUri(
      restBaseUrl: ref.read(apiConfigProvider).baseUrl,
      token: token,
      groupId: widget.groupId,
      roomId: _roomId,
    );
    final client = ChatLiveClient();
    _live = client;
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
      case ChatLiveReactionsUpdated():
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
      _joinState = _JoinState.joined;
      _composerUnlocked = true;
    });
    unawaited(_persistRoomId(roomId));
    unawaited(_markRoomRead());
  }

  void _onMessageCreated(Map<String, dynamic> json) {
    final roomId = _roomId;
    if (roomId == null || json.isEmpty) return;
    final message = ChatMessageDTO.fromJson(json);
    if (message.id.isEmpty) return;
    ref.read(groupChatThreadProvider(roomId).notifier).appendLive(message);
    unawaited(_markRoomRead());
  }

  Future<void> _refreshThread() async {
    final roomId = _roomId;
    if (roomId == null) return;
    await ref.read(groupChatThreadProvider(roomId).notifier).refreshLatest();
  }

  void _scheduleReconnect() {
    if (!mounted || _joinState != _JoinState.joined) return;
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

  void _onJoinBannerTap() {
    setState(() => _composerUnlocked = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bodyFocusNode.requestFocus();
    });
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending || !_composerUnlocked) return;
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
            _joinState = _JoinState.joined;
            _composerUnlocked = true;
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

    final isMember = switch (followState) {
      GroupFollowSuccess(isFollowing: final following) => following,
      GroupFollowLoading() => profile.isFollowing,
      GroupFollowFailure() => false,
    };

    if (followState is GroupFollowLoading && !profile.isFollowing) {
      return _buildShell(context, profile: profile, body: _buildLoading());
    }

    if (!isMember) {
      _leaveChat(toHome: false, notAMember: true);
      return _buildShell(
        context,
        profile: profile,
        body: const SizedBox.shrink(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_bootstrapJoinState());
    });

    final showComposer = _joinState != _JoinState.checking;
    final composerEnabled =
        _joinState == _JoinState.joined || _composerUnlocked;
    final showBanner = _joinState == _JoinState.preJoin && !_composerUnlocked;
    final roomId = _roomId;

    return _buildShell(
      context,
      profile: profile,
      body: switch (_joinState) {
        _JoinState.checking => _buildLoading(),
        _JoinState.preJoin => const SizedBox.expand(),
        _JoinState.joined =>
          roomId == null
              ? _buildLoading()
              : GroupChatThread(
                roomId: roomId,
                groupId: widget.groupId,
                currentUserId: _currentUserId,
              ),
      },
      showComposer: showComposer,
      composerEnabled: composerEnabled,
      showBanner: showBanner,
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required Widget body,
    GroupProfile? profile,
    bool showComposer = false,
    bool composerEnabled = false,
    bool showBanner = false,
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
            if (showBanner) GroupChatJoinBanner(onJoin: _onJoinBannerTap),
            if (showComposer)
              GroupChatComposer(
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                hintText: context.l10n.group_chat_message_hint,
                isSending: _sending,
                enabled: composerEnabled,
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
