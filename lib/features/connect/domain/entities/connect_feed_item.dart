import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

enum ConnectFeedItemType { post, event }

class ConnectFeedItem {
  final ConnectFeedItemType type;
  final DateTime? feedAt;
  final bool isJoined;
  final String groupId;
  final String groupName;
  final String? groupSlug;
  final String? groupAvatarUrl;
  final ConnectPost? post;
  final GroupEvent? event;

  const ConnectFeedItem({
    required this.type,
    this.feedAt,
    this.isJoined = false,
    required this.groupId,
    required this.groupName,
    this.groupSlug,
    this.groupAvatarUrl,
    this.post,
    this.event,
  });

  ConnectFeedItem copyWithPost(ConnectPost updatedPost) {
    return ConnectFeedItem(
      type: type,
      feedAt: feedAt,
      isJoined: isJoined,
      groupId: groupId,
      groupName: groupName,
      groupSlug: groupSlug,
      groupAvatarUrl: groupAvatarUrl,
      post: updatedPost,
      event: event,
    );
  }
}

class ConnectFeedPage {
  final List<ConnectFeedItem> items;
  final int skip;
  final int limit;
  final int total;

  const ConnectFeedPage({
    required this.items,
    required this.skip,
    required this.limit,
    required this.total,
  });

  bool get hasMore => skip + items.length < total;
}
