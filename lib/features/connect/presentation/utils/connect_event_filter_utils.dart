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
  final format = event.eventFormat;
  if (format != null) return format == ConnectEventFormatFilter.online.apiValue;
  final locationId = event.locationId?.trim();
  return locationId == null || locationId.isEmpty;
}

bool isGroupEventHybrid(GroupEvent event) =>
    event.eventFormat == ConnectEventFormatFilter.hybrid.apiValue;

/// Location name for the event, suffixed with [hybridLabel] on hybrid events
/// since they run in person and online at once.
String groupEventLocationLabel(
  GroupEvent event,
  String onlineLabel, {
  String? hybridLabel,
}) {
  final name = event.location?.name.trim();
  final hasName = name != null && name.isNotEmpty;

  if (isGroupEventHybrid(event) && hybridLabel != null) {
    return hasName ? '$name / $hybridLabel' : hybridLabel;
  }
  if (hasName && !isGroupEventOnline(event)) return name;
  return onlineLabel;
}
