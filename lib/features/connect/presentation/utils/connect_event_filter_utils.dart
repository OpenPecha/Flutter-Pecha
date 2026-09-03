import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

enum ConnectEventFormatFilter { all, online, offline, hybrid }

extension ConnectEventFormatFilterX on ConnectEventFormatFilter {
  /// `event_format` query value; null on the "All" tab, which sends no filter.
  String? get apiValue => switch (this) {
    ConnectEventFormatFilter.all => null,
    ConnectEventFormatFilter.online => 'online',
    ConnectEventFormatFilter.offline => 'offline',
    ConnectEventFormatFilter.hybrid => 'hybrid',
  };
}

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

