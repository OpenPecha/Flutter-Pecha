import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';

/// How an event link should be presented in the UI.
enum GroupEventLinkKind {
  /// Playable media, shown as a thumbnail with a play button.
  video,

  /// A live meeting room (Google Meet, Zoom, ...), shown as a join row.
  meeting,

  /// Anything else, shown as a plain link row.
  link,
}

abstract final class GroupEventLinkUtils {
  /// Hosts that open a live meeting room rather than a playable video.
  static const Map<String, String> _meetingHosts = {
    'meet.google.com': 'Google Meet',
    'zoom.us': 'Zoom',
    'zoomgov.com': 'Zoom',
    'teams.microsoft.com': 'Microsoft Teams',
    'teams.live.com': 'Microsoft Teams',
    'webex.com': 'Webex',
    'whereby.com': 'Whereby',
    'meet.jit.si': 'Jitsi Meet',
    'gotomeeting.com': 'GoTo Meeting',
    'goto.com': 'GoTo Meeting',
    'skype.com': 'Skype',
    'discord.gg': 'Discord',
    'discord.com': 'Discord',
  };

  static const Map<String, String> _videoHosts = {
    'youtube.com': 'YouTube',
    'youtube-nocookie.com': 'YouTube',
    'youtu.be': 'YouTube',
    'vimeo.com': 'Vimeo',
    'dailymotion.com': 'Dailymotion',
  };

  static const List<String> _videoFileExtensions = [
    '.mp4',
    '.mov',
    '.m4v',
    '.webm',
    '.m3u8',
  ];

  static GroupEventLinkKind kindOf(GroupEventLink link) {
    final host = _hostOf(link.url);
    if (host != null) {
      if (_lookupHost(host, _meetingHosts) != null) {
        return GroupEventLinkKind.meeting;
      }
      if (_lookupHost(host, _videoHosts) != null) {
        return GroupEventLinkKind.video;
      }
    }
    if (_hasVideoFileExtension(link.url)) return GroupEventLinkKind.video;

    final type = link.type.toLowerCase();
    if (type.contains('meet') ||
        type.contains('zoom') ||
        type.contains('call')) {
      return GroupEventLinkKind.meeting;
    }
    if (type.contains('video') || type.contains('youtube')) {
      return GroupEventLinkKind.video;
    }
    return GroupEventLinkKind.link;
  }

  /// Human readable name for the link. A recognised provider names itself
  /// ("Google Meet"), so the row never shows a placeholder label the backend
  /// happens to carry; otherwise the label, then the bare host.
  static String displayLabel(
    GroupEventLink link, {
    required String fallbackLabel,
  }) {
    final provider = providerName(link);
    if (provider != null) return provider;
    final label = link.label?.trim();
    if (label != null && label.isNotEmpty) return label;
    return _hostOf(link.url) ?? fallbackLabel;
  }

  /// Provider name for a known host, e.g. "Google Meet" or "YouTube".
  /// Null for hosts we do not recognise.
  static String? providerName(GroupEventLink link) {
    final host = _hostOf(link.url);
    if (host == null) return null;
    return _lookupHost(host, _meetingHosts) ?? _lookupHost(host, _videoHosts);
  }

  /// Compact form of the url used as a secondary line, e.g.
  /// "meet.google.com/abc-defg-hij".
  static String shortUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return url.trim();
    final host = _stripWww(uri.host);
    final path =
        uri.path.endsWith('/')
            ? uri.path.substring(0, uri.path.length - 1)
            : uri.path;
    return '$host$path';
  }

  static String? _hostOf(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return null;
    return _stripWww(uri.host.toLowerCase());
  }

  static String _stripWww(String host) =>
      host.startsWith('www.') ? host.substring(4) : host;

  static String? _lookupHost(String host, Map<String, String> hosts) {
    for (final entry in hosts.entries) {
      if (host == entry.key || host.endsWith('.${entry.key}')) {
        return entry.value;
      }
    }
    return null;
  }

  static bool _hasVideoFileExtension(String url) {
    final path = (Uri.tryParse(url.trim())?.path ?? url).toLowerCase();
    return _videoFileExtensions.any(path.endsWith);
  }
}
