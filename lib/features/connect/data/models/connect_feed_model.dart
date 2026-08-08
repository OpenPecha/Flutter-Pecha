import 'package:flutter_pecha/features/connect/data/models/connect_post_model.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/connect/domain/entities/connect_post.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_event_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

class ConnectFeedItemModel {
  final ConnectFeedItemType type;
  final DateTime? feedAt;
  final bool isJoined;
  final String groupId;
  final String groupName;
  final String? groupSlug;
  final String? groupAvatarUrl;
  final ConnectPost? post;
  final GroupEvent? event;

  const ConnectFeedItemModel({
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

  factory ConnectFeedItemModel.fromJson(
    Map<String, dynamic> json, {
    required String language,
  }) {
    final typeRaw = (json['type'] as String? ?? '').toLowerCase();
    final type =
        typeRaw == 'post'
            ? ConnectFeedItemType.post
            : ConnectFeedItemType.event;

    ConnectPost? post;
    if (json['post'] is Map<String, dynamic>) {
      post =
          ConnectPostModel.fromJson(
            json['post'] as Map<String, dynamic>,
          ).toEntity();
    }

    GroupEvent? event;
    if (json['event'] is Map<String, dynamic>) {
      event =
          GroupEventModel.fromJson(
            json['event'] as Map<String, dynamic>,
            language: language,
          ).toEntity();
    }

    return ConnectFeedItemModel(
      type: type,
      feedAt: _parseDateTime(json['feed_at']),
      isJoined: json['is_joined'] as bool? ?? false,
      groupId: json['group_id'] as String? ?? '',
      groupName: json['group_name'] as String? ?? '',
      groupSlug: json['group_slug'] as String?,
      groupAvatarUrl: json['group_avatar_url'] as String?,
      post: post,
      event: event,
    );
  }

  ConnectFeedItem toEntity() {
    return ConnectFeedItem(
      type: type,
      feedAt: feedAt,
      isJoined: isJoined,
      groupId: groupId,
      groupName: groupName,
      groupSlug: groupSlug,
      groupAvatarUrl: groupAvatarUrl,
      post: post,
      event: event,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class ConnectFeedPageModel {
  final List<ConnectFeedItemModel> items;
  final int skip;
  final int limit;
  final int total;

  const ConnectFeedPageModel({
    required this.items,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory ConnectFeedPageModel.fromJson(
    Map<String, dynamic> json, {
    required String language,
  }) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final items =
        itemsJson
            .whereType<Map<String, dynamic>>()
            .map(
              (item) => ConnectFeedItemModel.fromJson(
                item,
                language: language,
              ),
            )
            .where((item) {
              return switch (item.type) {
                ConnectFeedItemType.post => item.post != null,
                ConnectFeedItemType.event => item.event != null,
              };
            })
            .toList();

    return ConnectFeedPageModel(
      items: items,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? items.length,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }

  ConnectFeedPage toEntity() {
    return ConnectFeedPage(
      items: items.map((item) => item.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
