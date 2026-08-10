import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';

class ConnectPostCommentUserModel {
  final String? firstName;
  final String? lastName;
  final String email;
  final String? avatarUrl;

  const ConnectPostCommentUserModel({
    this.firstName,
    this.lastName,
    required this.email,
    this.avatarUrl,
  });

  factory ConnectPostCommentUserModel.fromJson(Map<String, dynamic> json) {
    return ConnectPostCommentUserModel(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  ConnectPostCommentUser toEntity() {
    return ConnectPostCommentUser(
      firstName: firstName,
      lastName: lastName,
      email: email,
      avatarUrl: avatarUrl,
    );
  }
}

class ConnectPostCommentModel {
  final String id;
  final String postId;
  final String? parentCommentId;
  final ConnectPostCommentUserModel user;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final bool likedByMe;

  const ConnectPostCommentModel({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.user,
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.likedByMe = false,
  });

  factory ConnectPostCommentModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final user =
        userJson is Map<String, dynamic>
            ? ConnectPostCommentUserModel.fromJson(userJson)
            : ConnectPostCommentUserModel(
              email: json['user_email'] as String? ?? '',
            );

    return ConnectPostCommentModel(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      parentCommentId: json['parent_comment_id'] as String?,
      user: user,
      text: json['text'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  ConnectPostComment toEntity() {
    return ConnectPostComment(
      id: id,
      postId: postId,
      parentCommentId: parentCommentId,
      user: user.toEntity(),
      text: text,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likeCount: likeCount,
      likedByMe: likedByMe,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class ConnectPostCommentsPageModel {
  final List<ConnectPostCommentModel> comments;
  final int skip;
  final int limit;
  final int total;

  const ConnectPostCommentsPageModel({
    required this.comments,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory ConnectPostCommentsPageModel.fromJson(Map<String, dynamic> json) {
    final commentsJson = json['comments'] as List<dynamic>? ?? const [];
    final comments =
        commentsJson
            .whereType<Map<String, dynamic>>()
            .map(ConnectPostCommentModel.fromJson)
            .toList();

    return ConnectPostCommentsPageModel(
      comments: comments,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? comments.length,
      total: (json['total'] as num?)?.toInt() ?? comments.length,
    );
  }

  ConnectPostCommentsPage toEntity() {
    return ConnectPostCommentsPage(
      comments: comments.map((comment) => comment.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
