import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanInfo extends ConsumerWidget {
  const PlanInfo({super.key, required this.plan});
  final PlansModel plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plan Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanImage(context),
            SizedBox(height: 20),
            _buildPlanTitleDays(context),
            SizedBox(height: 20),
            _buildActionButtons(context, isGuest),
            SizedBox(height: 20),
            _buildPlanDescription(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanImage(BuildContext context) {
    return Hero(
      tag: plan.title,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/bg.jpg',
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPlanTitleDays(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          plan.title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        Text(
          '${plan.totalDays} Days',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isGuest) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => context.push('/plans/details'),
        // onPressed: isGuest ? null : () => context.push('/plans/details'),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: isGuest ? Colors.grey[300] : Colors.black,
          foregroundColor: isGuest ? Colors.grey[600] : Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          isGuest ? 'Login Required' : 'Start Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPlanDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          plan.description ?? 'No description available.',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
