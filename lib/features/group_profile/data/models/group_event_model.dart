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

class GroupEventParticipantModel {
  final String userId;
  final DateTime? createdAt;
  final String? username;
  final String? fullname;
  final String? avatarUrl;

  const GroupEventParticipantModel({
    required this.userId,
    this.createdAt,
    this.username,
    this.fullname,
    this.avatarUrl,
  });

  factory GroupEventParticipantModel.fromJson(Map<String, dynamic> json) {
    return GroupEventParticipantModel(
      userId: json['user_id'] as String? ?? '',
      createdAt: GroupEventModel._parseDate(json['created_at']),
      username: json['username'] as String?,
      fullname: json['fullname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  GroupEventParticipant toEntity() {
    return GroupEventParticipant(
      userId: userId,
      createdAt: createdAt,
      username: username,
      fullname: fullname,
      avatarUrl: avatarUrl,
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
  final bool isJoined;
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
    this.isJoined = false,
    this.links = const [],
    this.planId,
    this.accumulatorId,
    this.mantraId,
    this.timerId,
    this.groupRecitationCollectionId,
  });

  factory GroupEventModel.fromJson(
    Map<String, dynamic> json, {
    String? language,
  }) {
    final imageJson = json['image'] as Map<String, dynamic>?;

    return GroupEventModel(
      id: json['id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      isOneDay: json['is_one_day'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      metadata: _parseMetadata(json['metadata'], language: language),
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      isJoined: json['is_joined'] as bool? ?? false,
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
      isJoined: isJoined,
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

  static GroupEventMetadataModel? _parseMetadata(
    Object? value, {
    String? language,
  }) {
    if (value is Map<String, dynamic>) {
      return GroupEventMetadataModel.fromJson(value);
    }
    if (value is List<dynamic>) {
      final items = value.whereType<Map<String, dynamic>>().toList();
      if (language != null && language.isNotEmpty) {
        final match = items
            .where((item) => item['language'] == language)
            .firstOrNull;
        if (match != null) {
          return GroupEventMetadataModel.fromJson(match);
        }
      }
      final metadataJson = items.firstOrNull;
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

  factory GroupEventsPageModel.fromJson(
    Map<String, dynamic> json, {
    String? language,
  }) {
    return GroupEventsPageModel(
      events:
          (json['events'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((item) => GroupEventModel.fromJson(item, language: language))
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

class GroupEventParticipantsPageModel {
  final List<GroupEventParticipantModel> participants;
  final int skip;
  final int limit;
  final int total;

  const GroupEventParticipantsPageModel({
    required this.participants,
    this.skip = 0,
    this.limit = 20,
    this.total = 0,
  });

  factory GroupEventParticipantsPageModel.fromJson(Map<String, dynamic> json) {
    return GroupEventParticipantsPageModel(
      participants:
          (json['participants'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupEventParticipantModel.fromJson)
              .toList() ??
          const [],
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  GroupEventParticipantsPage toEntity() {
    return GroupEventParticipantsPage(
      participants:
          participants.map((participant) => participant.toEntity()).toList(),
      skip: skip,
      limit: limit,
      total: total,
    );
  }
}
