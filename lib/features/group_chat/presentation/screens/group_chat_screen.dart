import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_chat/data/datasource/group_chat_live_client.dart';
import 'package:flutter_pecha/features/group_chat/presentation/chat_send_error.dart';
import 'package:flutter_pecha/features/group_chat/presentation/providers/group_chat_providers.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_composer.dart';
import 'package:flutter_pecha/features/group_chat/presentation/widgets/group_chat_header.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Member-gated chat shell. The message thread ships in a later task.
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();
  ChatLiveClient? _live;
  StreamSubscription<ChatLiveEvent>? _liveSub;
  bool _redirecting = false;
  bool _sending = false;
  bool _liveStarted = false;

  @override
  void dispose() {
    unawaited(_tearDownLive());
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
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

  /// Leaves the chat once membership is denied or the session is not eligible.
  /// [notAMember] is reserved for a confirmed non-member; a failed profile load
  /// leaves silently because the cause is unknown.
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

  Future<void> _ensureLiveConnected() async {
    if (_live != null) return;
    final token = await ref.read(authServiceProvider).getValidAccessToken();
    if (!mounted || token == null) return;
    final uri = ChatLiveClient.liveUri(
      restBaseUrl: ref.read(apiConfigProvider).baseUrl,
      token: token,
      groupId: widget.groupId,
    );
    final client = ChatLiveClient();
    _live = client;
    _liveSub = client.connect(uri).listen((event) {
      if (!mounted) return;
      if (event is ChatLiveError) {
        presentChatSendError(context, event);
      }
    });
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await ref
        .read(groupChatRepositoryProvider)
        .sendGroupMessage(widget.groupId, body: body);
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold((failure) => presentChatSendError(context, failure), (_) {
      _bodyController.clear();
    });
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
      if (!mounted || _liveStarted) return;
      _liveStarted = true;
      unawaited(_ensureLiveConnected());
    });

    return _buildShell(
      context,
      profile: profile,
      body: _buildEmptyThread(context),
      showComposer: true,
    );
  }

  /// Every state shares this frame so the header does not shift or restyle
  /// between loading, denial, and the live chat.
  Widget _buildShell(
    BuildContext context, {
    required Widget body,
    GroupProfile? profile,
    bool showComposer = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // The composer pads itself past the keyboard instead.
      resizeToAvoidBottomInset: false,
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            GroupChatHeader(isDark: isDark, onBack: _goBack, profile: profile),
            Expanded(
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: body,
              ),
            ),
            if (showComposer)
              GroupChatComposer(
                controller: _bodyController,
                focusNode: _bodyFocusNode,
                hintText: context.l10n.group_chat_message_hint,
                isSending: _sending,
                onSubmit: _send,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyThread(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          context.l10n.group_chat_coming_soon,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color:
                isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
            height: getLineHeight(locale.languageCode),
          ),
        ),
      ),
    );
  }
}
