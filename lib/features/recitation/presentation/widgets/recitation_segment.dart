import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_text_section.dart';

/// A widget that displays a single segment of recitation content.
///
/// This widget handles the rendering of different content types
/// (recitation, translation, transliteration, adaptation) based on
/// the specified display order.
class RecitationSegment extends StatelessWidget {
  /// The segment data to display
  final RecitationSegmentModel segment;

  final List<ContentType> contentOrder;

  final bool isFirstSegment;

  const RecitationSegment({
    super.key,
    required this.segment,
    required this.contentOrder,
    this.isFirstSegment = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add height for segments after the first one
        if (!isFirstSegment) ...[const SizedBox(height: 26)],

        // Render content in the specified order
        ...contentOrder.expand((contentType) {
          return _buildContentForType(contentType);
        }),
      ],
    );
  }

  /// Builds the widgets for a specific content type.
  ///
  /// Returns an empty list if the content type is not available
  /// in this segment.
  List<Widget> _buildContentForType(ContentType contentType) {
    final contentMap = _getContentMap(contentType);
    if (contentMap == null || contentMap.isEmpty) {
      return [];
    }

    // Build widgets for each text entry with spacing
    return contentMap.entries.expand((entry) sync* {
      // Add spacing between different language entries
      // (but not before the first one)
      if (entry.key != contentMap.keys.first) {
        yield const SizedBox(height: 8);
      }

      // entry.key is the language code (e.g., 'bo', 'en', 'zh')
      // entry.value contains the text content
      yield RecitationTextSection(
        text: entry.value.content,
        languageCode: entry.key,
      );
    }).toList();
  }

  /// Gets the content map for a specific content type.
  ///
  /// Returns null if the content type is not available in this segment.
  Map<String, RecitationTextModel>? _getContentMap(ContentType contentType) {
    return switch (contentType) {
      ContentType.recitation => segment.recitation,
      ContentType.translation => segment.translations,
      ContentType.transliteration => segment.transliterations,
      ContentType.adaptation => segment.adaptations,
    };
  }
}
