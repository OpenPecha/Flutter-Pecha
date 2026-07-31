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
    this.links = const [],
    this.planId,
    this.accumulatorId,
    this.mantraId,
    this.timerId,
    this.groupRecitationCollectionId,
  });
}
