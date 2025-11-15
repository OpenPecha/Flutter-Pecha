import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/plans/data/providers/author_providers.dart';
import 'package:flutter_pecha/features/plans/models/author/author_model.dart';
import 'package:flutter_pecha/features/plans/models/author/social_profile_dto.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorDetailScreen extends ConsumerWidget {
  final String authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch full author details using the author ID
    final authorDetails = ref.watch(authorByIdFutureProvider(authorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Author'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: authorDetails.when(
        data: (authorData) => _buildAuthorContent(context, authorData),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => ErrorStateWidget(
              error: error,
              customMessage: 'Unable to load author details.\nPlease try again.',
              onRetry: () {
                ref.invalidate(authorByIdFutureProvider(authorId));
              },
            ),
      ),
    );
  }

  Widget _buildAuthorContent(BuildContext context, AuthorModel authorData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, authorData),
          _buildBioSection(context, authorData),
          _buildPlansCreatedSection(context, authorData.id),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthorModel authorData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: authorData.id,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    authorData.imageUrl?.isNotEmpty ?? false
                        ? authorData.imageUrl!.cachedNetworkImageProvider
                        : null,
                backgroundColor: Colors.grey[800],
                child:
                    authorData.imageUrl?.isEmpty ?? true
                        ? const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      authorData.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (authorData.email.isNotEmpty)
                      Text(
                        authorData.email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 12),
                    if (authorData.socialProfiles.isNotEmpty)
                      _buildSocialIcons(context, authorData.socialProfiles),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcons(
    BuildContext context,
    List<SocialProfileDto> socialProfiles,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          socialProfiles.map((profile) {
            return InkWell(
              onTap:
                  () => _launchSocialUrl(context, profile.url, profile.account),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FaIcon(
                  _getSocialIcon(profile.account.toLowerCase()),
                  size: 22,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            );
          }).toList(),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'email':
        return FontAwesomeIcons.envelope;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'twitter':
      case 'x':
        return FontAwesomeIcons.xTwitter;
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      case 'website':
      case 'web':
        return FontAwesomeIcons.globe;
      default:
        return FontAwesomeIcons.link;
    }
  }

  Future<void> _launchSocialUrl(
    BuildContext context,
    String url,
    String account,
  ) async {
    try {
      final Uri uri;
      if (account.toLowerCase() == 'email') {
        uri = Uri.parse('mailto:$url');
      } else {
        uri = Uri.parse(url);
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Cannot open this link');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Invalid URL format');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBioSection(BuildContext context, AuthorModel authorData) {
    if (authorData.bio == null || authorData.bio!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
      child: Text(
        authorData.bio!,
        style: const TextStyle(fontSize: 14, height: 1.7),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _buildPlansCreatedSection(BuildContext context, String authorId) {
    return Consumer(
      builder: (context, ref, child) {
        final plansAsync = ref.watch(authorPlansFutureProvider(authorId));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Plans Created',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            plansAsync.when(
              data: (plans) {
                if (plans.isEmpty) {
                  return _buildEmptyPlansState(context);
                }
                return _buildPlansList(context, plans);
              },
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (error, stackTrace) =>
                      _buildPlansErrorState(context, ref, authorId),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlansList(BuildContext context, List<PlansModel> plans) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _buildPlanCard(context, plan);
        },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, PlansModel plan) {
    return GestureDetector(
      onTap: () {
        // context.push(
        //   '/plans/info',
        //   extra: {'plan': plan, 'author': plan.author},
        // );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImageWidget(
              imageUrl: plan.imageUrl ?? '',
              width: 120,
              height: 90,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.totalDays} days',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                plan.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlansState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No plans created yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansErrorState(
    BuildContext context,
    WidgetRef ref,
    String authorId,
  ) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to load plans',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(authorPlansFutureProvider(authorId));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
