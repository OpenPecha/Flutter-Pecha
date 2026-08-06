class ConnectPostComment {
  final String id;
  final String postId;
  final String userId;
  final String? parentCommentId;
  final String userEmail;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool likedByMe;

  const ConnectPostComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentCommentId,
    required this.userEmail,
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  bool get isReply =>
      parentCommentId != null && parentCommentId!.trim().isNotEmpty;

  ConnectPostComment copyWith({
    int? likeCount,
    bool? likedByMe,
  }) {
    return ConnectPostComment(
      id: id,
      postId: postId,
      userId: userId,
      parentCommentId: parentCommentId,
      userEmail: userEmail,
      text: text,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount ?? this.likeCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}

class ConnectPostCommentsPage {
  final List<ConnectPostComment> comments;
  final int skip;
  final int limit;
  final int total;

  const ConnectPostCommentsPage({
    required this.comments,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + comments.length < total;
}
