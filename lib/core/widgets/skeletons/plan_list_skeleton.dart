import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton loading widget for the plan list screen.
///
/// Displays shimmer-animated placeholder content that mimics the
/// [PlanListScreen] layout with a featured card and list items.
/// Dynamically calculates the number of items based on screen size.
class PlanListSkeleton extends StatelessWidget {
  const PlanListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final listItemCount = _calculateListItemCount(context, constraints);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Skeletonizer.zone(
          effect: ShimmerEffect(
            baseColor: isDark ? const Color(0xFF3A3A3A) : AppColors.greyLight,
            highlightColor:
                isDark ? const Color(0xFF4A4A4A) : AppColors.grey50,
          ),
          child: CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              // Featured/Banner Card skeleton
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildFeaturedCardSkeleton(context),
                ),
              ),
              // Spacing
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Plan list skeletons
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildListItemSkeleton(context),
                    childCount: listItemCount,
                  ),
                ),
              ),
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  int _calculateListItemCount(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (!constraints.maxHeight.isFinite) {
      return 4;
    }

    final cardWidth = (constraints.maxWidth - 32).clamp(0.0, double.infinity);
    final featuredImageHeight = cardWidth / (16 / 9);
    const featuredTextHeight = 12 + 20 + 8 + 14 + 14 + 46 + 16;
    final featuredHeight = featuredImageHeight + featuredTextHeight;

    // Each list item is ~86 height + 12 bottom margin
    final availableForList = constraints.maxHeight - featuredHeight - 16 - 24;
    final itemHeight = 86 + 12.0;
    final visibleItems = (availableForList / itemHeight).ceil();
    // Show enough items to fill visible area, minimum 3, maximum 8
    return visibleItems.clamp(3, 8);
  }

  Widget _buildFeaturedCardSkeleton(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: Bone(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(
                  width: 180,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Bone(
                  width: 240,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 14),
                Bone(
                  width: double.infinity,
                  height: 46,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail skeleton
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            clipBehavior: Clip.antiAlias,
            child: const Bone(
              width: 86,
              height: 86,
              borderRadius: BorderRadius.zero,
            ),
          ),
          const SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Bone(
                  width: 160,
                  height: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Bone(
                  width: 200,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
