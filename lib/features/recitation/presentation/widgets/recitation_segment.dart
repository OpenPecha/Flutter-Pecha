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
        if (!isFirstSegment) const SizedBox(height: 26),
        ..._buildAllContent(),
      ],
    );
  }

  /// Builds all content widgets with proper global index tracking across content types.
  List<Widget> _buildAllContent() {
    final widgets = <Widget>[];
    var globalIndex = 0;

    for (final contentType in contentOrder) {
      final contentMap = _getContentMap(contentType);
      if (contentMap == null || contentMap.isEmpty) {
        continue;
      }

      // Process each text entry in this content type
      for (final entry in contentMap.entries) {
        // Add spacing between entries (but not before the first one)
        if (globalIndex > 0) {
          widgets.add(const SizedBox(height: 8));
        }

        widgets.add(
          RecitationTextSection(
            text: entry.value.content,
            languageCode: entry.key,
            textIndex: globalIndex,
          ),
        );

        globalIndex++;
      }
    }

    return widgets;
  }

  /// Gets the content map for a specific content type.
  Map<String, RecitationTextModel>? _getContentMap(ContentType contentType) {
    return switch (contentType) {
      ContentType.recitation => segment.recitation,
      ContentType.translation => segment.translations,
      ContentType.transliteration => segment.transliterations,
      ContentType.adaptation => segment.adaptations,
    };
  }
}
