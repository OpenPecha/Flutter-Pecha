import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';

class UserPlanCard extends StatelessWidget {
  final UserPlansModel plan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const UserPlanCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = InkWell(
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
    );

    // Wrap with Dismissible if onDelete is provided
    if (onDelete != null) {
      return Dismissible(
        key: Key(plan.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _showConfirmationDialog(context),
        onDismissed: (direction) => onDelete!(),
        background: _buildDismissBackground(context),
        child: card,
      );
    }

    return card;
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unenroll from Plan'),
          content: Text(
            'Are you sure you want to unenroll from "${plan.title}"? Your progress will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Unenroll'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onError,
        size: 32,
      ),
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
