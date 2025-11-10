import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/presentation/author_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanInfo extends ConsumerStatefulWidget {
  // Changed to StatefulWidget
  const PlanInfo({super.key, required this.plan, required this.author});
  final PlansModel plan;
  final AuthorDtoModel author;
  @override
  ConsumerState<PlanInfo> createState() => _PlanInfoState();
}

class _PlanInfoState extends ConsumerState<PlanInfo> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;
    final isLoggedIn = authState.isLoggedIn;
    var subscribedPlans = AsyncValue<UserPlanListResponseModel>.data(
      UserPlanListResponseModel(userPlans: [], total: 0, skip: 0, limit: 0),
    );

    if (!isGuest && isLoggedIn) {
      subscribedPlans = ref.watch(userPlansFutureProvider);
    }
    final subscribedPlansIds =
        subscribedPlans.valueOrNull?.userPlans.map((e) => e.id).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
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
            _buildActionButtons(context, subscribedPlansIds, isGuest),
            SizedBox(height: 20),
            _buildPlanDescription(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanImage(BuildContext context) {
    return Hero(
      tag: widget.plan.title,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.plan.imageUrl ?? '',
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPlanTitleDays(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.plan.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '${widget.plan.totalDays} Days',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        _buildAuthorAvatar(context),
      ],
    );
  }

  Widget _buildAuthorAvatar(BuildContext context) {
    final author = widget.author;
    final authorImage = author.imageUrl;
    final authorId = author.id;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthorDetailScreen(authorId: authorId),
          ),
        );
      },
      child: CircleAvatar(
        radius: 20,
        backgroundImage:
            authorImage.isNotEmpty ? NetworkImage(authorImage) : null,
        backgroundColor: Colors.grey[300],
        child:
            authorImage.isEmpty
                ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                : null,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    List<String> subscribedPlansIds,
    bool isGuest,
  ) {
    final isSubscribed = subscribedPlansIds.contains(widget.plan.id);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed:
            () =>
                isGuest
                    ? ref.read(authProvider.notifier).logout()
                    : isSubscribed
                    ? handleContinuePlan()
                    : handleStartPlan(),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          isGuest
              ? 'Login to Continue'
              : isSubscribed
              ? 'Continue Plan'
              : 'Start Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> handleContinuePlan() async {
    if (mounted) {
      context.push('/plans/details', extra: widget.plan);
    }
  }

  // Updated handleStartPlan function
  Future<void> handleStartPlan() async {
    final planId = widget.plan.id;
    debugPrint('planId: $planId');

    try {
      // Subscribe to plan using the authenticated HTTP client
      final success = await ref.read(
        userPlanSubscribeFutureProvider(planId).future,
      );

      if (success) {
        // Success: Show plan listed in my plans
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully enrolled in ${widget.plan.title}!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Invalidate both user plans providers to refresh the data
          ref.invalidate(userPlansFutureProvider);
          ref.invalidate(myPlansPaginatedProvider);

          // Wait a moment for the data to refresh, then navigate
          await Future.delayed(Duration(milliseconds: 500));

          if (mounted) {
            context.pop(true); // Return true to indicate successful enrollment
          }
        }
      } else {
        // Failed to enroll
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enroll in plan. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors during enrollment
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enrolling in plan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
        Text(widget.plan.description, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
