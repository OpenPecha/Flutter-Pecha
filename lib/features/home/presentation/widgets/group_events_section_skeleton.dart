import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class GroupEventsSectionSkeleton extends StatelessWidget {
  const GroupEventsSectionSkeleton({super.key});

  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalPadding,
        0,
        _horizontalPadding,
        16,
      ),
      child: Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Bone.text(words: 2, fontSize: 18)),
                Bone.text(words: 2, fontSize: 14),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 2; i++) ...[
              Bone(
                width: double.infinity,
                height: 220,
                borderRadius: BorderRadius.circular(0),
              ),
              if (i == 0) const SizedBox(height: 0),
            ],
          ],
        ),
      ),
    );
  }
}
