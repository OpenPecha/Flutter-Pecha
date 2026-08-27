import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

enum ConnectEventLocationFilter { all, online, inPerson }

bool isGroupEventOnline(GroupEvent event) {
  final locationId = event.locationId?.trim();
  return locationId == null || locationId.isEmpty;
}

bool isGroupEventInPerson(GroupEvent event) => !isGroupEventOnline(event);

String groupEventLocationLabel(GroupEvent event, String onlineLabel) {
  final locationId = event.locationId?.trim();
  if (locationId != null && locationId.isNotEmpty) {
    final name = event.location?.name.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  return onlineLabel;
}

List<GroupEvent> filterGroupEventsByLocation(
  List<GroupEvent> events,
  ConnectEventLocationFilter filter,
) {
  return switch (filter) {
    ConnectEventLocationFilter.all => events,
    ConnectEventLocationFilter.online =>
      events.where(isGroupEventOnline).toList(growable: false),
    ConnectEventLocationFilter.inPerson =>
      events.where(isGroupEventInPerson).toList(growable: false),
  };
}
