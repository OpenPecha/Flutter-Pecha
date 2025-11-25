import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_pecha/shared/extensions/typography_extensions.dart';

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
          Expanded(child: _buildPlanInfo(context, plan)),
        ],
      ),
    );

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
    final localizations = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.plan_unenroll),
          content: Text(
            languageCode == 'bo'
                ? '${plan.title} ${localizations.unenroll_confirmation}\n\n ${localizations.unenroll_message}'
                : '${localizations.unenroll_confirmation} "${plan.title}"?\n\n ${localizations.unenroll_message}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(localizations.plan_unenroll),
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

Widget _buildPlanInfo(BuildContext context, UserPlansModel plan) {
  final planLanguage = plan.language;
  final fontSize = planLanguage == 'bo' ? 18.0 : 16.0;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      Text(
        '${plan.totalDays} Days',
        style: context.languageTextStyle(
          planLanguage,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        plan.title,
        style: context.languageTitleStyle(planLanguage),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
