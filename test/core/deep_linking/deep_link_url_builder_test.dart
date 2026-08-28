import 'package:flutter_pecha/core/deep_linking/deep_link_router.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkUrlBuilder.groupAccumulatorLink', () {
    test('builds accumulator link with group query param', () {
      final uri = DeepLinkUrlBuilder.groupAccumulatorLink(
        accumulatorId: 'acc-123',
        groupId: 'grp-456',
      );

      expect(
        uri.toString(),
        'https://webuddhist.com/open/group-accumulator/acc-123?group=grp-456',
      );
    });

    test('is recognized as a first-party app link', () {
      final uri = DeepLinkUrlBuilder.groupAccumulatorLink(
        accumulatorId: 'acc-123',
        groupId: 'grp-456',
      );

      expect(DeepLinkRouter.isFirstPartyAppLink(uri), isTrue);
    });
  });

  group('DeepLinkUrlBuilder.poemLink', () {
    test('builds poem link with poem id', () {
      final uri = DeepLinkUrlBuilder.poemLink(poemId: 'poem-42');

      expect(uri.toString(), 'https://webuddhist.com/open/poem/poem-42');
    });

    test('is recognized as a first-party app link', () {
      final uri = DeepLinkUrlBuilder.poemLink(poemId: 'poem-42');

      expect(DeepLinkRouter.isFirstPartyAppLink(uri), isTrue);
    });
  });
}
