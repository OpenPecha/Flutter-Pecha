import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/plans/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/author_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanInfo extends ConsumerStatefulWidget {
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanImage(context),
            SizedBox(height: 16),
            _buildPlanTitleDays(context),
            SizedBox(height: 16),
            _buildActionButtons(
              context,
              subscribedPlansIds,
              isGuest,
              subscribedPlans,
            ),
            SizedBox(height: 16),
            Text(widget.plan.description, style: const TextStyle(fontSize: 16)),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanImage(BuildContext context) {
    return CachedNetworkImageWidget(
      imageUrl: widget.plan.imageUrl ?? '',
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
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
    final authorImage = author.authorImageThumbnail;
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
            authorImage?.isNotEmpty ?? false
                ? authorImage!.cachedNetworkImageProvider
                : null,
        backgroundColor: Colors.grey[300],
        child:
            authorImage?.isEmpty ?? true
                ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                : null,
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    List<String> subscribedPlansIds,
    bool isGuest,
    AsyncValue<UserPlanListResponseModel> subscribedPlans,
  ) {
    final isSubscribed = subscribedPlansIds.contains(widget.plan.id);
    final buttonText = _getButtonText(isGuest, isSubscribed);
    final userPlan = _findUserPlan(subscribedPlans);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => _handleButtonAction(isGuest, isSubscribed, userPlan),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  UserPlansModel? _findUserPlan(
    AsyncValue<UserPlanListResponseModel> subscribedPlans,
  ) {
    final userPlans = subscribedPlans.valueOrNull?.userPlans;
    if (userPlans == null) return null;

    final matchingPlans = userPlans.where(
      (userPlan) => userPlan.id == widget.plan.id,
    );
    return matchingPlans.isNotEmpty ? matchingPlans.first : null;
  }

  String _getButtonText(bool isGuest, bool isSubscribed) {
    final localizations = AppLocalizations.of(context)!;
    if (isGuest) return localizations.sign_in;
    if (isSubscribed) return localizations.continue_plan;
    return localizations.start_plan;
  }

  Future<void> _handleButtonAction(
    bool isGuest,
    bool isSubscribed,
    UserPlansModel? userPlan,
  ) async {
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }

    if (isSubscribed && userPlan != null) {
      await handleContinuePlan(userPlan);
    } else {
      await handleStartPlan();
    }
  }

  Future<void> handleContinuePlan(UserPlansModel userPlan) async {
    if (!mounted) return;

    final selectedDay = PlanUtils.calculateSelectedDay(
      userPlan.startedAt,
      userPlan.totalDays,
    );

    context.push(
      '/plans/details',
      extra: {
        'plan': userPlan,
        'selectedDay': selectedDay,
        'startDate': userPlan.startedAt,
      },
    );
  }

  // Updated handleStartPlan function
  Future<void> handleStartPlan() async {
    final planId = widget.plan.id;

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
              content: Text('Unable to enroll in plan. Please try again.'),
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
            content: Text('Unable to enroll in plan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
