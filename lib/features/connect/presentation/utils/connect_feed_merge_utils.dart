import 'package:flutter_pecha/features/connect/domain/entities/connect_feed_item.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';

/// Merges feed and practice items into a single chronologically sorted list.
abstract final class ConnectFeedMergeUtils {
  static List<ConnectFeedItem> merge({
    required List<ConnectFeedItem> feedItems,
    required List<GroupPractice> practices,
  }) {
    final practiceItems = practices
        .map(ConnectFeedItem.fromPractice)
        .toList(growable: false);
    return sortAndDedupe([...feedItems, ...practiceItems]);
  }

  static List<ConnectFeedItem> sortAndDedupe(List<ConnectFeedItem> items) {
    final seen = <String>{};
    final unique = <ConnectFeedItem>[];

    for (final item in items) {
      final key = item.dedupeKey;
      if (seen.add(key)) {
        unique.add(item);
      }
    }

    unique.sort((a, b) {
      final aDate = a.sortDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.sortDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return unique;
  }

  static List<ConnectFeedItem> applyFilter(
    List<ConnectFeedItem> items,
    ConnectFeedFilterType filter,
  ) {
    return switch (filter) {
      ConnectFeedFilterType.all => items,
      ConnectFeedFilterType.posts =>
        items.where((item) => item.type == ConnectFeedItemType.post).toList(),
      ConnectFeedFilterType.events =>
        items.where((item) => item.type == ConnectFeedItemType.event).toList(),
      ConnectFeedFilterType.practices =>
        items
            .where((item) => item.type == ConnectFeedItemType.practice)
            .toList(),
    };
  }
}

enum ConnectFeedFilterType { all, posts, events, practices }

extension ConnectFeedFilterTypeMapping on ConnectFeedFilterType {
  static ConnectFeedFilterType fromIndex(int index) {
    return ConnectFeedFilterType.values[index.clamp(
      0,
      ConnectFeedFilterType.values.length - 1,
    )];
  }
}
