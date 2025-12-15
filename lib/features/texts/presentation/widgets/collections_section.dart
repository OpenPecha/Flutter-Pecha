import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionsSection extends ConsumerWidget {
  final Collections collection;
  final Color dividerColor;

  const CollectionsSection({
    super.key,
    required this.collection,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontFamily = getFontFamily(collection.language);
    final lineHeight = getLineHeight(collection.language);
    final fontSize = 22.0;
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: dividerColor, thickness: 3, height: 4),
          const SizedBox(height: 8),
          Text(
            collection.title,
            style: TextStyle(
              fontFamily: fontFamily,
              height: lineHeight,
              fontSize: fontSize.toDouble(),
            ),
          ),
          const SizedBox(height: 2),
          if (collection.description.isNotEmpty)
            Text(
              collection.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16.0,
                height: lineHeight,
                fontFamily: fontFamily,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
