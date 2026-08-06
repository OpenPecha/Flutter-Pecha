import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_post_comments_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/utils/connect_comment_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectPostCommentTile extends ConsumerStatefulWidget {
  const ConnectPostCommentTile({
    super.key,
    required this.comment,
    required this.postId,
    this.onReply,
  });

  final ConnectPostComment comment;
  final String postId;
  final ValueChanged<ConnectPostComment>? onReply;

  @override
  ConsumerState<ConnectPostCommentTile> createState() =>
      _ConnectPostCommentTileState();
}

class _ConnectPostCommentTileState extends ConsumerState<ConnectPostCommentTile> {
  bool? _likedOverride;
  int? _likeCountOverride;
  bool _isSubmittingLike = false;

  bool get _isLiked => _likedOverride ?? widget.comment.likedByMe;

  int get _likeCount {
    final base = _likeCountOverride ?? widget.comment.likeCount;
    if (_likedOverride == null) return base;
    if (_likedOverride! && !widget.comment.likedByMe) return base + 1;
    if (!_likedOverride! && widget.comment.likedByMe) {
      return (base - 1).clamp(0, 1 << 31);
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final comment = widget.comment;
    final displayName = connectCommentDisplayName(comment.userEmail);
    final relativeTime = connectCommentRelativeTime(comment.createdAt);
    final currentUserId = ref.watch(userProvider).user?.id;
    final isOwnComment =
        currentUserId != null && currentUserId == comment.userId;
    final indent = comment.isReply ? 44.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentAvatar(name: displayName, isDark: isDark),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                            height: 1.3,
                          ),
                          children: [
                            TextSpan(
                              text: displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (relativeTime.isNotEmpty) ...[
                              TextSpan(
                                text: ' · $relativeTime',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (isOwnComment)
                      PopupMenuButton<String>(
                        icon: Icon(
                          AppAssets.dotsThreeVertical,
                          size: 18,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textSecondary,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') _confirmDelete(comment);
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _CommentText(text: comment.text, isDark: isDark),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed:
                          widget.onReply == null
                              ? null
                              : () => widget.onReply!(comment),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _CommentLikeButton(
                      isLiked: _isLiked,
                      likeCount: _likeCount,
                      isLoading: _isSubmittingLike,
                      isDark: isDark,
                      onTap: () => _toggleLike(comment),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(ConnectPostComment comment) async {
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

    final success = await ref
        .read(connectPostCommentsProvider(widget.postId).notifier)
        .toggleCommentLike(comment);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isSubmittingLike = false;
        _likedOverride = wasLiked;
      });
      return;
    }

    setState(() {
      _isSubmittingLike = false;
      _likeCountOverride = _likeCount;
    });
  }

  Future<void> _confirmDelete(ConnectPostComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete comment?'),
            content: const Text(
              'This comment will be permanently removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(connectPostCommentsProvider(widget.postId).notifier)
        .deleteComment(comment.id);

    if (!mounted || success) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Failed to delete comment')));
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.name, required this.isDark});

  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CommentText extends StatelessWidget {
  const _CommentText({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mentionMatch = RegExp(r'^@([A-Za-z0-9._-]+)\s*').firstMatch(text);
    if (mentionMatch == null) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      );
    }

    final mention = mentionMatch.group(0) ?? '';
    final rest = text.substring(mention.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        children: [
          TextSpan(
            text: mention,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer(),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }
}

class _CommentLikeButton extends StatelessWidget {
  const _CommentLikeButton({
    required this.isLiked,
    required this.likeCount,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
  });

  final bool isLiked;
  final int likeCount;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final defaultColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isLiked ? AppColors.error : defaultColor,
                ),
              )
            else
              Icon(
                isLiked ? AppAssets.heartFill : AppAssets.heart,
                size: 16,
                color: isLiked ? AppColors.error : defaultColor,
              ),
            if (likeCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$likeCount',
                style: TextStyle(
                  fontSize: 13,
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
