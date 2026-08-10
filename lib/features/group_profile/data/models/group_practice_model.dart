import 'package:flutter_pecha/features/group_profile/data/models/group_accumulator_model.dart';
import 'package:flutter_pecha/features/group_profile/data/models/group_profile_model.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_practice.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

class GroupPracticeModel {
  final GroupPracticeType type;
  final Map<String, dynamic>? seriesJson;
  final Map<String, dynamic>? accumulatorJson;

  GroupPracticeModel({
    required this.type,
    this.seriesJson,
    this.accumulatorJson,
  });

  factory GroupPracticeModel.fromJson(Map<String, dynamic> json) {
    final typeValue = (json['type'] as String? ?? '').toLowerCase();
    final type = switch (typeValue) {
      'accumulator' => GroupPracticeType.accumulator,
      'collection' => GroupPracticeType.collection,
      _ => GroupPracticeType.series,
    };

    return GroupPracticeModel(
      type: type,
      seriesJson: json['series'] as Map<String, dynamic>?,
      accumulatorJson: json['accumulator'] as Map<String, dynamic>?,
    );
  }

  GroupPractice toEntity() {
    return GroupPractice(
      type: type,
      series:
          seriesJson != null ? _parseSeries(seriesJson!) : null,
      accumulator:
          accumulatorJson != null
              ? GroupAccumulatorModel.fromJson(accumulatorJson!).toEntity()
              : null,
    );
  }

  GroupProfileSeries _parseSeries(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>?;
    final imageJson = json['image'] as Map<String, dynamic>?;

    return GroupProfileSeries(
      id: json['id'] as String? ?? '',
      title: meta?['title'] as String? ?? '',
      subTitle: meta?['sub_title'] as String?,
      description: meta?['description'] as String?,
      image: imageJson != null ? ResponsiveImage.fromJson(imageJson) : null,
      featured: json['featured'] as bool? ?? false,
      planCount: (json['plan_count'] as num?)?.toInt() ?? 0,
      totalDays: (json['total_days'] as num?)?.toInt() ?? 0,
      startDate: GroupProfileModel.parseDate(json['start_date']),
      endDate: GroupProfileModel.parseDate(json['end_date']),
      enrolledCount: (json['enrolled_count'] as num?)?.toInt() ?? 0,
      isGroupEnrolled: GroupProfileModel.parseNullableBool(
        json['is_group_enrolled'],
      ),
    );
  }
}

class GroupPracticesPageModel {
  final List<GroupPracticeModel> practices;
  final int total;
  final int skip;
  final int limit;

  GroupPracticesPageModel({
    required this.practices,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory GroupPracticesPageModel.fromJson(Map<String, dynamic> json) {
    return GroupPracticesPageModel(
      practices:
          (json['practices'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(GroupPracticeModel.fromJson)
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }

  GroupPracticesPage toEntity() {
    return GroupPracticesPage(
      practices: practices.map((item) => item.toEntity()).toList(),
      total: total,
      skip: skip,
      limit: limit,
    );
  }
}
