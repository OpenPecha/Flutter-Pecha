import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

enum GroupPracticeType { accumulator, series, collection }

class GroupPracticeCollection extends Equatable {
  final String id;
  final String groupId;
  final String name;
  final String? imageUrl;
  final int itemCount;
  final DateTime? createdAt;

  const GroupPracticeCollection({
    required this.id,
    required this.groupId,
    required this.name,
    this.imageUrl,
    this.itemCount = 0,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, groupId, name, imageUrl, itemCount, createdAt];
}

class GroupPractice extends Equatable {
  final GroupPracticeType type;
  final GroupProfileSeries? series;
  final GroupAccumulator? accumulator;
  final GroupPracticeCollection? collection;

  const GroupPractice({
    required this.type,
    this.series,
    this.accumulator,
    this.collection,
  });

  @override
  List<Object?> get props => [type, series, accumulator, collection];
}

class GroupPracticesPage extends Equatable {
  final List<GroupPractice> practices;
  final int total;
  final int skip;
  final int limit;

  const GroupPracticesPage({
    required this.practices,
    required this.total,
    required this.skip,
    required this.limit,
  });

  bool get hasMore => skip + practices.length < total;

  @override
  List<Object?> get props => [practices, total, skip, limit];
}
