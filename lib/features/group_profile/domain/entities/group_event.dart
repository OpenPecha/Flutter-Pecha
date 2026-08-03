import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupEventLink {
  final String id;
  final String type;
  final String url;
  final String? label;
  final int displayOrder;

  const GroupEventLink({
    required this.id,
    required this.type,
    required this.url,
    this.label,
    this.displayOrder = 0,
  });
}

class GroupEventParticipant {
  final String userId;
  final DateTime? createdAt;
  final String? username;
  final String? fullname;
  final String? avatarUrl;

  const GroupEventParticipant({
    required this.userId,
    this.createdAt,
    this.username,
    this.fullname,
    this.avatarUrl,
  });

  String get displayName {
    final name = fullname?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return handle;
    return 'Participant';
  }
}

class GroupEvent {
  final String id;
  final String groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOneDay;
  final bool featured;
  final String title;
  final String? description;
  final String? language;
  final ResponsiveImage? image;
  final int participantCount;
  final bool isJoined;
  final List<GroupEventLink> links;
  final String? planId;
  final String? accumulatorId;
  final String? mantraId;
  final String? timerId;
  final String? groupRecitationCollectionId;

  const GroupEvent({
    required this.id,
    required this.groupId,
    this.startDate,
    this.endDate,
    this.isOneDay = false,
    this.featured = false,
    this.title = '',
    this.description,
    this.language,
    this.image,
    this.participantCount = 0,
    this.isJoined = false,
    this.links = const [],
    this.planId,
    this.accumulatorId,
    this.mantraId,
    this.timerId,
    this.groupRecitationCollectionId,
  });
}

class GroupEventParticipantsPage {
  final List<GroupEventParticipant> participants;
  final int skip;
  final int limit;
  final int total;

  const GroupEventParticipantsPage({
    required this.participants,
    this.skip = 0,
    this.limit = 20,
    this.total = 0,
  });

  bool get hasMore => skip + participants.length < total;
}
