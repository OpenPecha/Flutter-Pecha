import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_link_utils.dart';
import 'package:flutter_test/flutter_test.dart';

GroupEventLink _link(String url, {String type = '', String? label}) =>
    GroupEventLink(id: '1', type: type, url: url, label: label);

void main() {
  group('GroupEventLinkUtils.kindOf', () {
    test('treats meeting rooms as meetings, not videos', () {
      const meetingUrls = [
        'https://meet.google.com/abc-defg-hij',
        'https://us02web.zoom.us/j/1234567890',
        'https://teams.microsoft.com/l/meetup-join/xyz',
        'https://meet.jit.si/pecha',
      ];
      for (final url in meetingUrls) {
        expect(
          GroupEventLinkUtils.kindOf(_link(url, type: 'video')),
          GroupEventLinkKind.meeting,
          reason: url,
        );
      }
    });

    test('treats known video hosts and media files as videos', () {
      const videoUrls = [
        'https://www.youtube.com/watch?v=abc123',
        'https://youtu.be/abc123',
        'https://vimeo.com/12345',
        'https://cdn.example.com/talks/opening.mp4',
      ];
      for (final url in videoUrls) {
        expect(
          GroupEventLinkUtils.kindOf(_link(url)),
          GroupEventLinkKind.video,
          reason: url,
        );
      }
    });

    test('falls back to the link type when the host is unknown', () {
      expect(
        GroupEventLinkUtils.kindOf(
          _link('https://example.com/stream', type: 'video'),
        ),
        GroupEventLinkKind.video,
      );
      expect(
        GroupEventLinkUtils.kindOf(_link('https://example.com/notes')),
        GroupEventLinkKind.link,
      );
    });
  });

  group('displayLabel', () {
    String label(GroupEventLink link) =>
        GroupEventLinkUtils.displayLabel(link, fallbackLabel: 'Open link');

    test('names a known provider even when the link carries a label', () {
      expect(
        label(_link('https://meet.google.com/abc', label: 'this is label')),
        'Google Meet',
      );
      expect(label(_link('https://us02web.zoom.us/j/123')), 'Zoom');
      expect(label(_link('https://youtu.be/abc123')), 'YouTube');
    });

    test('falls back to the label, then the host', () {
      expect(
        label(_link('https://example.com/notes', label: 'Retreat schedule')),
        'Retreat schedule',
      );
      expect(label(_link('https://example.com/notes')), 'example.com');
      expect(label(_link('not a url')), 'Open link');
    });
  });

  test('shortUrl drops the scheme, www and trailing slash', () {
    expect(
      GroupEventLinkUtils.shortUrl('https://www.meet.google.com/abc-defg/'),
      'meet.google.com/abc-defg',
    );
  });
}
