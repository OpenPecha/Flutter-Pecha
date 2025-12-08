import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_content_model.dart';
import 'package:flutter_pecha/features/recitation/domain/content_type.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_segment.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

class RecitationContent extends StatelessWidget {
  final RecitationContentModel content;
  final List<ContentType> contentOrder;
  final ScrollController? scrollController;
  final String language;

  const RecitationContent({
    super.key,
    required this.content,
    required this.contentOrder,
    this.scrollController,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(context),
          const SizedBox(height: 26),

          ...List.generate(
            content.segments.length,
            (index) => RecitationSegment(
              segment: content.segments[index],
              contentOrder: contentOrder,
              isFirstSegment: index == 0,
            ),
          ),

          // Extra bottom padding to ensure floating button doesn't cover text
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final fontFamily = getFontFamily(language);
    final fontSize = language == 'bo' ? 26.0 : 22.0;

    return Text(
      content.title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: fontFamily,
        fontSize: fontSize,
      ),
    );
  }
}
