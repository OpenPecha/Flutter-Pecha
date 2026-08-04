import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

class GroupEventsPage {
  final List<GroupEvent> events;
  final int total;
  final int skip;
  final int limit;

  const GroupEventsPage({
    required this.events,
    this.total = 0,
    this.skip = 0,
    this.limit = 20,
  });

  bool get hasMore => skip + events.length < total;
}
