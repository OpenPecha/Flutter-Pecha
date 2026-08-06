import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_comments_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_posts_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_comment_utils.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_comment_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class ConnectPostDetailScreen extends ConsumerStatefulWidget {
  const ConnectPostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
    this.includeUnfollowed = false,
  });

  final String postId;
  final ConnectPost? initialPost;
  final bool includeUnfollowed;

  @override
  ConsumerState<ConnectPostDetailScreen> createState() =>
      _ConnectPostDetailScreenState();
}

class _ConnectPostDetailScreenState
    extends ConsumerState<ConnectPostDetailScreen> {
  late ConnectPost _post;
  bool? _likedOverride;
  int? _likeCountOverride;
  bool _isSubmittingLike = false;
  bool _captionExpanded = false;
  ConnectPostComment? _replyTarget;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost ?? _emptyPost(widget.postId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  ConnectPost _emptyPost(String postId) {
    return ConnectPost(
      id: postId,
      groupId: '',
      caption: '',
      status: '',
      creatorName: '',
    );
  }

  bool get _isLiked => _likedOverride ?? _post.likedByMe;

  int get _likeCount {
    final base = _likeCountOverride ?? _post.likeCount;
    if (_likedOverride == null) return base;
    if (_likedOverride! && !_post.likedByMe) return base + 1;
    if (!_likedOverride! && _post.likedByMe) {
      return (base - 1).clamp(0, 1 << 31);
    }
    return base;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(connectPostCommentsProvider(widget.postId).notifier).loadMore();
    }
  }

  void _startReply(ConnectPostComment comment) {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() {
      _replyTarget = comment;
      _commentController.text =
          '@${connectCommentMentionHandle(comment.userEmail)} ';
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
    });
    _commentFocusNode.requestFocus();
  }

  void _clearReply() {
    setState(() => _replyTarget = null);
  }

  Future<void> _submitComment() async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await ref
        .read(connectPostCommentsProvider(widget.postId).notifier)
        .submitComment(
          text: text,
          parentCommentId: _replyTarget?.id,
        );

    if (!mounted || !success) return;

    _commentController.clear();
    _clearReply();
    _updatePostCommentCount(_post.commentCount + 1);
    _commentFocusNode.unfocus();
  }

  void _updatePostCommentCount(int count) {
    setState(() {
      _post = _post.copyWith(commentCount: count);
    });
    final provider =
        widget.includeUnfollowed
            ? discoverConnectPostsProvider
            : myConnectPostsProvider;
    ref.read(provider.notifier).updatePost(_post);
  }

  Future<void> _toggleLike() async {
    if (_isSubmittingLike) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final wasLiked = _isLiked;
    setState(() {
      _isSubmittingLike = true;
      _likedOverride = !wasLiked;
    });

    final repository = ref.read(connectRepositoryProvider);
    final result =
        wasLiked
            ? await repository.unlikePost(_post.id)
            : await repository.likePost(_post.id);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isSubmittingLike = false;
          _likedOverride = wasLiked;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (_) {
        final updatedPost = _post.copyWith(
          likedByMe: !wasLiked,
          likeCount: _likeCount,
        );
        setState(() {
          _isSubmittingLike = false;
          _likeCountOverride = updatedPost.likeCount;
          _post = updatedPost;
        });
        final provider =
            widget.includeUnfollowed
                ? discoverConnectPostsProvider
                : myConnectPostsProvider;
        ref.read(provider.notifier).updatePost(updatedPost);
      },
    );
  }

  Future<void> _sharePost() async {
    final caption = _post.caption.trim();
    final shareUrl =
        _post.groupId.isNotEmpty
            ? DeepLinkUrlBuilder.groupLink(groupId: _post.groupId).toString()
            : '';
    final message =
        caption.isNotEmpty && shareUrl.isNotEmpty
            ? '$caption\n\n$shareUrl'
            : caption.isNotEmpty
            ? caption
            : shareUrl;
    if (message.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final commentsState = ref.watch(connectPostCommentsProvider(widget.postId));
    final commentCount =
        commentsState.total > 0 ? commentsState.total : _post.commentCount;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, isDark),
            Expanded(
              child: _buildBody(context, isDark, commentsState, commentCount),
            ),
            _buildCommentComposer(context, isDark, commentsState.isSubmitting),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(AppAssets.x),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    ConnectPostCommentsState commentsState,
    int commentCount,
  ) {
    if (commentsState.isLoading && commentsState.comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (commentsState.error != null && commentsState.comments.isEmpty) {
      return ErrorStateWidget(
        error: commentsState.error!,
        onRetry:
            () =>
                ref
                    .read(connectPostCommentsProvider(widget.postId).notifier)
                    .retry(),
      );
    }

    final orderedComments = commentsState.orderedComments;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        _buildPostCard(context, isDark, commentCount),
        const SizedBox(height: 24),
        Text(
          '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (orderedComments.isEmpty && !commentsState.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No comments yet. Start the conversation.',
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
              ),
            ),
          )
        else
          ...orderedComments.map(
            (comment) => ConnectPostCommentTile(
              comment: comment,
              postId: widget.postId,
              onReply: _startReply,
            ),
          ),
        if (commentsState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPostCard(BuildContext context, bool isDark, int commentCount) {
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final caption = _post.caption.trim();
    final imageMedia =
        _post.media
            .where((item) => item.isImage && item.url.isNotEmpty)
            .toList();
    final shouldTruncate = caption.length > 180 && !_captionExpanded;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthorRow(
            name: _post.creatorName,
            avatarUrl: _post.creatorImageUrl,
            isDark: isDark,
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              caption,
              maxLines: shouldTruncate ? 4 : null,
              overflow: shouldTruncate ? TextOverflow.ellipsis : null,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            if (shouldTruncate)
              GestureDetector(
                onTap: () => setState(() => _captionExpanded = true),
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'more',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
          if (imageMedia.isNotEmpty) ...[
            const SizedBox(height: 12),
            _PostMediaGallery(media: imageMedia, isDark: isDark),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _PostActionButton(
                icon: _isLiked ? AppAssets.heartFill : AppAssets.heart,
                iconColor:
                    _isLiked
                        ? AppColors.error
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                count: _likeCount,
                isLoading: _isSubmittingLike,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 20),
              _PostActionButton(
                icon: AppAssets.chatCircle,
                count: commentCount,
                onTap: () => _commentFocusNode.requestFocus(),
              ),
              const Spacer(),
              _PostActionButton(
                icon: AppAssets.readerShare,
                onTap: _sharePost,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentComposer(
    BuildContext context,
    bool isDark,
    bool isSubmitting,
  ) {
    final canSend = _commentController.text.trim().isNotEmpty && !isSubmitting;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final fillColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.scaffoldBackgroundDark : AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        8,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyTarget != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to @${connectCommentMentionHandle(_replyTarget!.userEmail)}',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppAssets.x, size: 18),
                    onPressed: _clearReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitComment(),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        _replyTarget == null
                            ? 'Write a comment...'
                            : 'Write a reply...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: canSend ? _submitComment : null,
                icon:
                    isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Icon(
                          AppAssets.paperPlaneRight,
                          size: 22,
                          color:
                              canSend
                                  ? AppColors.primaryDark
                                  : (isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textSecondary),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAuthorRow extends StatelessWidget {
  const _PostAuthorRow({
    required this.name,
    this.avatarUrl,
    required this.isDark,
  });

  final String name;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : 'Author';

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
              isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
          backgroundImage:
              avatarUrl != null && avatarUrl!.isNotEmpty
                  ? avatarUrl!.cachedNetworkImageProvider
                  : null,
          child:
              avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(
                    AppAssets.profile,
                    size: 16,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textSecondary,
                  )
                  : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PostMediaGallery extends StatelessWidget {
  const _PostMediaGallery({required this.media, required this.isDark});

  final List<ConnectPostMedia> media;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return _PostMediaTile(url: media.first.url, isDark: isDark);
    }

    final visibleMedia = media.take(2).toList();
    return Row(
      children: [
        for (var i = 0; i < visibleMedia.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _PostMediaTile(url: visibleMedia[i].url, isDark: isDark),
          ),
        ],
      ],
    );
  }
}

class _PostMediaTile extends StatelessWidget {
  const _PostMediaTile({required this.url, required this.isDark});

  final String url;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: CachedNetworkImageWidget(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: ColoredBox(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            child: Icon(
              AppAssets.photoLibrary,
              color: isDark ? AppColors.grey500 : AppColors.grey600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.count,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final int? count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor ?? defaultColor,
                ),
              )
            else
              Icon(icon, size: 20, color: iconColor ?? defaultColor),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: defaultColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
