import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';

class UserPlanCard extends StatelessWidget {
  final UserPlansModel plan;
  final VoidCallback onTap;
  const UserPlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return
    // Card(
    //   // color: Theme.of(context).cardColor,
    //   color: Colors.transparent,
    //   margin: const EdgeInsets.only(bottom: 16.0),
    //   elevation: 2,
    //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    //   child:
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanImage(plan),
          const SizedBox(width: 24),
          Expanded(child: _buildPlanInfo(plan)),
        ],
      ),
      // ),
    );
  }
}

Widget _buildPlanImage(UserPlansModel plan) {
  return CachedNetworkImageWidget(
    imageUrl: plan.imageUrl ?? '',
    width: 90,
    height: 90,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.circular(12),
    heroTag: plan.title,
  );
}

Widget _buildPlanInfo(UserPlansModel plan) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      Text(
        '${plan.totalDays} Days',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      Text(
        plan.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
