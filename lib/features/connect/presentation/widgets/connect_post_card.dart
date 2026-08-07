import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_like_actions.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_like_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

class ConnectPostCard extends ConsumerStatefulWidget {
  const ConnectPostCard({
    super.key,
    required this.post,
    this.includeUnfollowed = false,
    this.syncFeedProvider = false,
  });

  final ConnectPost post;
  final bool includeUnfollowed;
  final bool syncFeedProvider;

  @override
  ConsumerState<ConnectPostCard> createState() => _ConnectPostCardState();
}

class _ConnectPostCardState extends ConsumerState<ConnectPostCard> {
  final ConnectOptimisticLikeState _likeState = ConnectOptimisticLikeState();

  bool get _isLiked => _likeState.isLiked(widget.post.likedByMe);

  int get _likeCount => _likeState.likeCount(
    serverLikeCount: widget.post.likeCount,
    serverLikedByMe: widget.post.likedByMe,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final post = widget.post;
    final caption = post.caption.trim();
    final imageMedia =
        post.media
            .where((item) => item.isImage && item.url.isNotEmpty)
            .toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openDetail,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorRow(
                  name: post.creatorName,
                  avatarUrl: post.creatorImageUrl,
                  isDark: isDark,
                ),
                if (caption.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (imageMedia.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PostMediaGallery(media: imageMedia, isDark: isDark),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ActionButton(
                      icon: _isLiked ? AppAssets.heartFill : AppAssets.heart,
                      iconColor:
                          _isLiked
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                      count: _likeCount,
                      isLoading: _likeState.isSubmitting,
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 20),
                    _ActionButton(
                      icon: AppAssets.chatCircle,
                      count: post.commentCount,
                      onTap: _openDetail,
                    ),
                    const Spacer(),
                    _ActionButton(
                      icon: AppAssets.readerShare,
                      onTap: () => _sharePost(post),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail() {
    context.push(
      '/home/posts/${widget.post.id}',
      extra: {
        'post': widget.post,
        'includeUnfollowed': widget.includeUnfollowed,
      },
    );
  }

  Future<void> _toggleLike() async {
    if (_likeState.isSubmitting) return;

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final wasLiked = _isLiked;
    setState(() => _likeState.beginToggle(wasLiked));

    final result = await ref
        .read(connectPostLikeActionsProvider)
        .toggleLike(
          post: widget.post,
          wasLiked: wasLiked,
          optimisticLikeCount: _likeCount,
          includeUnfollowed: widget.includeUnfollowed,
          syncFeed: widget.syncFeedProvider,
        );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _likeState.revert(wasLiked));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
      return;
    }

    setState(
      () => _likeState.commitSuccess(
        serverLikeCount: widget.post.likeCount,
        serverLikedByMe: widget.post.likedByMe,
      ),
    );
  }

  Future<void> _sharePost(ConnectPost post) async {
    final caption = post.caption.trim();
    final shareUrl =
        post.groupId.isNotEmpty
            ? DeepLinkUrlBuilder.groupLink(groupId: post.groupId).toString()
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
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.name, this.avatarUrl, required this.isDark});

  final String name;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : context.l10n.author;

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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      ),
    );
  }
}
