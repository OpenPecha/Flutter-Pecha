import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_events_page.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupEventMetadataModel {
  final String id;
  final String name;
  final String? description;
  final String language;

  const GroupEventMetadataModel({
    required this.id,
    required this.name,
    this.description,
    required this.language,
  });

  factory GroupEventMetadataModel.fromJson(Map<String, dynamic> json) {
    return GroupEventMetadataModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      language: json['language'] as String? ?? '',
    );
  }
}

class GroupEventLinkModel {
  final String id;
  final String type;
  final String url;
  final String? label;
  final int displayOrder;

  const GroupEventLinkModel({
    required this.id,
    required this.type,
    required this.url,
    this.label,
    this.displayOrder = 0,
  });

  factory GroupEventLinkModel.fromJson(Map<String, dynamic> json) {
    return GroupEventLinkModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      label: json['label'] as String?,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  GroupEventLink toEntity() {
    return GroupEventLink(
      id: id,
      type: type,
      url: url,
      label: label,
      displayOrder: displayOrder,
    );
  }
}

class GroupEventModel {
  final String id;
  final String groupId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOneDay;
  final bool featured;
  final GroupEventMetadataModel? metadata;
  final ResponsiveImage? image;
  final int participantCount;
  final List<GroupEventLinkModel> links;
  final String? planId;
  final String? accumulatorId;
  final String? mantraId;
  final String? timerId;
  final String? groupRecitationCollectionId;

  const GroupEventModel({
    required this.id,
    required this.groupId,
    this.startDate,
    this.endDate,
    this.isOneDay = false,
    this.featured = false,
    this.metadata,
    this.image,
    this.participantCount = 0,
    this.links = const [],
    this.planId,
    this.accumulatorId,
    this.mantraId,
    this.timerId,
    this.groupRecitationCollectionId,
  });

  factory GroupEventModel.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'] as Map<String, dynamic>?;

    return GroupEventModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      isOneDay: json['is_one_day'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      metadata: _parseMetadata(json['metadata']),
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      links:
          (json['links'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupEventLinkModel.fromJson)
              .toList() ??
          const [],
      planId: json['plan_id'] as String?,
      accumulatorId: json['accumulator_id'] as String?,
      mantraId: json['mantra_id'] as String?,
      timerId: json['timer_id'] as String?,
      groupRecitationCollectionId:
          json['group_recitation_collection_id'] as String?,
    );
  }

  GroupEvent toEntity() {
    return GroupEvent(
      id: id,
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
      isOneDay: isOneDay,
      featured: featured,
      title: metadata?.name ?? '',
      description: metadata?.description,
      language: metadata?.language,
      image: image,
      participantCount: participantCount,
      links: links.map((link) => link.toEntity()).toList(),
      planId: planId,
      accumulatorId: accumulatorId,
      mantraId: mantraId,
      timerId: timerId,
      groupRecitationCollectionId: groupRecitationCollectionId,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static GroupEventMetadataModel? _parseMetadata(Object? value) {
    if (value is Map<String, dynamic>) {
      return GroupEventMetadataModel.fromJson(value);
    }
    if (value is List<dynamic>) {
      final metadataJson = value.whereType<Map<String, dynamic>>().firstOrNull;
      if (metadataJson != null) {
        return GroupEventMetadataModel.fromJson(metadataJson);
      }
    }
    return null;
  }
}

class GroupEventsPageModel {
  final List<GroupEventModel> events;
  final int total;
  final int skip;
  final int limit;

  const GroupEventsPageModel({
    required this.events,
    this.total = 0,
    this.skip = 0,
    this.limit = 20,
  });

  factory GroupEventsPageModel.fromJson(Map<String, dynamic> json) {
    return GroupEventsPageModel(
      events:
          (json['events'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupEventModel.fromJson)
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }

  GroupEventsPage toEntity() {
    return GroupEventsPage(
      events: events.map((event) => event.toEntity()).toList(),
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}
