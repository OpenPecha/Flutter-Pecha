import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

enum GroupPracticeType { accumulator, series, collection }

class GroupPractice extends Equatable {
  final GroupPracticeType type;
  final GroupProfileSeries? series;
  final GroupAccumulator? accumulator;

  const GroupPractice({
    required this.type,
    this.series,
    this.accumulator,
  });

  @override
  List<Object?> get props => [type, series, accumulator];
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

  @override
  List<Object?> get props => [practices, total, skip, limit];
}
