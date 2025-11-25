import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_segment.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// A widget that displays the full content of a recitation.
///
/// This widget handles:
/// - Displaying the recitation title
/// - Rendering all segments in order
/// - Applying consistent layout and spacing
class RecitationContent extends StatelessWidget {
  /// The recitation content to display
  final RecitationContentModel content;

  /// The order in which to display different content types within segments
  final List<ContentType> contentOrder;

  const RecitationContent({
    super.key,
    required this.content,
    required this.contentOrder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildTitle(context),
          const SizedBox(height: 26),

          // Segments
          ...List.generate(
            content.segments.length,
            (index) => RecitationSegment(
              segment: content.segments[index],
              contentOrder: contentOrder,
              isFirstSegment: index == 0,
            ),
          ),

          // Bottom spacing
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Builds the title widget with proper styling.
  Widget _buildTitle(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final fontFamily = getFontFamily(languageCode);
    final fontSize = languageCode == 'bo' ? 26.0 : 22.0;

    return Text(
      content.title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        fontSize: fontSize,
      ),
    );
  }
}
