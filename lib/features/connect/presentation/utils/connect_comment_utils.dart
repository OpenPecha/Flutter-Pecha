import 'package:flutter_pecha/features/connect/domain/entities/connect_post_comment.dart';

String connectCommentRelativeTime(DateTime? dateTime) {
  if (dateTime == null) return '';

  final local = dateTime.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  if (diff.inDays < 30) return '${diff.inDays ~/ 7}w';
  return '${local.day}/${local.month}';
}

bool isConnectCommentOwnedByEmail({
  required ConnectPostComment comment,
  required String? currentUserEmail,
}) {
  final commentEmail = comment.user.email.trim().toLowerCase();
  final ownerEmail = currentUserEmail?.trim().toLowerCase();
  if (commentEmail.isEmpty || ownerEmail == null || ownerEmail.isEmpty) {
    return false;
  }
  return commentEmail == ownerEmail;
}

/// Builds a threaded comment list from a flat API response.
List<ConnectPostComment> orderConnectPostComments(
  List<ConnectPostComment> comments,
) {
  if (comments.isEmpty) return const [];

  final byParent = <String?, List<ConnectPostComment>>{};
  for (final comment in comments) {
    final parentId =
        comment.parentCommentId != null &&
                comment.parentCommentId!.trim().isNotEmpty
            ? comment.parentCommentId
            : null;
    byParent.putIfAbsent(parentId, () => []).add(comment);
  }

  int compareComments(ConnectPostComment a, ConnectPostComment b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aTime.compareTo(bTime);
  }

  for (final group in byParent.values) {
    group.sort(compareComments);
  }

  final ordered = <ConnectPostComment>[];
  void appendThread(String? parentId) {
    final children = byParent[parentId];
    if (children == null) return;

    for (final comment in children) {
      ordered.add(comment);
      appendThread(comment.id);
    }
  }

  appendThread(null);
  return ordered;
}
