import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PlanCard extends ConsumerWidget {
  final PlansModel plan;
  final VoidCallback onTap;
  const PlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanImage(plan),
              const SizedBox(width: 24),
              Expanded(child: _buildPlanInfo(plan, ref)),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildPlanImage(PlansModel plan) {
  return CachedNetworkImageWidget(
    imageUrl: plan.imageThumbnail ?? '',
    width: 90,
    height: 90,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.circular(12),
    heroTag: plan.title,
  );
}

Widget _buildPlanInfo(PlansModel plan, WidgetRef ref) {
  final languageCode = ref.watch(localeProvider).languageCode;
  final fontFamily = getFontFamily(languageCode);
  final lineHeight = getLineHeight(languageCode);
  final fontSize = languageCode == 'bo' ? 22.0 : 18.0;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      Text(
        '${plan.totalDays} Days',
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
          height: lineHeight,
        ),
      ),
      Text(
        plan.title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
          height: lineHeight,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
