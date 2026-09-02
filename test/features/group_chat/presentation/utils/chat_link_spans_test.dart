import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_link_spans.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findChatLinks', () {
    test('returns nothing for a body with no URL', () {
      expect(findChatLinks('hi everyone, great to be part of it'), isEmpty);
    });

    test('extracts an http URL with its offsets', () {
      const body = 'see https://pecha.org/texts for the reading';
      final links = findChatLinks(body);

      expect(links, hasLength(1));
      expect(links.single.text, 'https://pecha.org/texts');
      expect(
        body.substring(links.single.start, links.single.end),
        'https://pecha.org/texts',
      );
    });

    test('strips trailing sentence punctuation', () {
      expect(
        findChatLinks('read https://pecha.org/texts.').single.text,
        'https://pecha.org/texts',
      );
      expect(
        findChatLinks('is it https://pecha.org/a?').single.text,
        'https://pecha.org/a',
      );
    });

    test('keeps a closing bracket the URL opened itself', () {
      expect(
        findChatLinks(
          'see https://en.wikipedia.org/wiki/Sutta_(text)',
        ).single.text,
        'https://en.wikipedia.org/wiki/Sutta_(text)',
      );
    });

    test('drops an unmatched closing bracket', () {
      expect(
        findChatLinks('(link https://pecha.org/a)').single.text,
        'https://pecha.org/a',
      );
    });

    test('finds several links in order', () {
      final links = findChatLinks('https://a.org and https://b.org');
      expect(links.map((link) => link.text).toList(), [
        'https://a.org',
        'https://b.org',
      ]);
    });

    test('opens a bare www host over https', () {
      final link = findChatLinks('try www.pecha.org today').single;
      expect(link.text, 'www.pecha.org');
      expect(link.url, 'https://www.pecha.org');
    });

    test('ignores a host with no dot', () {
      expect(findChatLinks('http://localhost'), isEmpty);
    });
  });

  group('firstChatLinkUrl', () {
    test('returns the first URL', () {
      expect(
        firstChatLinkUrl('a https://one.org b https://two.org'),
        'https://one.org',
      );
    });

    test('returns null when there is nothing to unfurl', () {
      expect(firstChatLinkUrl('no links here'), isNull);
    });
  });
}
