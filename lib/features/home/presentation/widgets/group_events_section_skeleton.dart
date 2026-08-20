import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class GroupEventsSectionSkeleton extends StatelessWidget {
  const GroupEventsSectionSkeleton({super.key});

  static const _horizontalPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            0,
            _horizontalPadding,
            0,
          ),
          child: Skeletonizer(
            enabled: true,
            child: Row(
              children: [
                Expanded(child: Bone.text(words: 2, fontSize: 18)),
                Bone.text(words: 2, fontSize: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Skeletonizer(
          enabled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < 2; i++) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Bone.square(size: 32, borderRadius: BorderRadius.circular(16)),
                      const SizedBox(width: 10),
                      Expanded(child: Bone.text(words: 3, fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Bone.text(words: 3, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Bone(
                  width: double.infinity,
                  height: 72,
                  borderRadius: BorderRadius.circular(0),
                ),
                if (i == 0) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
