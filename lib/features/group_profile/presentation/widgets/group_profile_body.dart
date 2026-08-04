import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/deep_linking/deep_link_url_builder.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/tibetan_numerals.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_pecha/features/group_profile/presentation/screens/group_about_screen.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_accumulator_card.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_events_tab.dart';
import 'package:flutter_pecha/features/group_profile/presentation/utils/group_profile_link_utils.dart';
import 'package:flutter_pecha/features/group_profile/presentation/widgets/group_profile_members_tab.dart';
import 'package:flutter_pecha/features/home/presentation/providers/series_enrollment_provider.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_date_format.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class GroupProfileBody extends ConsumerStatefulWidget {
  final GroupProfile profile;
  final bool isDark;
  final VoidCallback? onSeriesTap;

  const GroupProfileBody({
    super.key,
    required this.profile,
    required this.isDark,
    this.onSeriesTap,
  });

  @override
  ConsumerState<GroupProfileBody> createState() => _GroupProfileBodyState();
}

class _GroupProfileBodyState extends ConsumerState<GroupProfileBody>
    with SingleTickerProviderStateMixin {
  static const int _practicesTabIndex = 2;
  static const int _membersTabIndex = 3;

  TabController? _tabController;
  String? _enrollingSeriesId;
  String? _joiningAccumulatorId;
  final Set<String> _localGroupEnrolledSeriesIds = {};
  ProviderSubscription<bool>? _membersTabActiveSub;
  ProviderSubscription<bool>? _membersNeedsRefreshSub;
  late final TapGestureRecognizer _moreRecognizer;

  bool _isCommunityGroup(GroupProfile profile) => !profile.groupType.isPage;

  bool _hasBanner(GroupProfile profile) =>
      profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty;

  String? _aboutDescription(GroupProfile profile) {
    final descriptionLong = profile.descriptionLong?.trim();
    if (descriptionLong != null && descriptionLong.isNotEmpty) {
      return descriptionLong;
    }

    final description = profile.description?.trim();
    if (description != null && description.isNotEmpty) {
      return description;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _moreRecognizer = TapGestureRecognizer();
    if (_isCommunityGroup(widget.profile)) {
      _tabController = TabController(
        length: 4,
        initialIndex: _practicesTabIndex,
        vsync: this,
      );
      _tabController!.addListener(_onTabChanged);

      final groupId = widget.profile.id;
      // Keep tab/refresh flags alive while this screen is mounted so join/unjoin
      // refresh logic can set and consume them reliably, without rebuilding
      // this widget when the flags change.
      _membersTabActiveSub = ref.listenManual(
        groupMembersTabActiveProvider(groupId),
        (_, _) {},
      );
      _membersNeedsRefreshSub = ref.listenManual(
        groupMembersNeedsRefreshProvider(groupId),
        (_, _) {},
      );
    }
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) return;
    if (!mounted) return;

    final groupId = widget.profile.id;
    final isMembersTab = _tabController!.index == _membersTabIndex;
    ref.read(groupMembersTabActiveProvider(groupId).notifier).state =
        isMembersTab;

    if (isMembersTab && ref.read(groupMembersNeedsRefreshProvider(groupId))) {
      ref.read(groupMembersNeedsRefreshProvider(groupId).notifier).state =
          false;
      if (ref.exists(groupMembersProvider(groupId))) {
        ref.read(groupMembersProvider(groupId).notifier).loadInitial();
      }
    }
  }

  @override
  void dispose() {
    _membersTabActiveSub?.close();
    _membersNeedsRefreshSub?.close();
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _moreRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followKey = GroupFollowKey(
      groupId: widget.profile.id,
      groupType: widget.profile.groupType,
    );
    ref.listen(groupFollowProvider(followKey), (previous, next) {
      if (next case GroupFollowSuccess(isFollowing: false)) {
        setState(_localGroupEnrolledSeriesIds.clear);
        ref
            .read(groupAccumulatorJoinCacheProvider(widget.profile.id).notifier)
            .clear();
        ref.invalidate(groupAccumulatorsProvider(widget.profile.id));
      }
    });
    ref.listen(groupAccumulatorsProvider(widget.profile.id), (previous, next) {
      next.whenData((either) {
        either.fold((_) {}, (page) {
          ref
              .read(
                groupAccumulatorJoinCacheProvider(widget.profile.id).notifier,
              )
              .syncFromApi(page.accumulators);
        });
      });
    });
    ref.listen(groupProfileProvider(widget.profile.id), (previous, next) {
      next.whenData((either) {
        either.fold((_) {}, (profile) {
          final apiEnrolledIds =
              profile.series
                  .where((series) => series.isGroupEnrolled == true)
                  .map((series) => series.id)
                  .toSet();
          final apiNotEnrolledIds = profile.series
              .where((series) => series.isGroupEnrolled == null)
              .map((series) => series.id);
          setState(() {
            _localGroupEnrolledSeriesIds.addAll(apiEnrolledIds);
            _localGroupEnrolledSeriesIds.removeAll(apiNotEnrolledIds);
          });
        });
      });
    });

    final enrollingId = _enrollingSeriesId;
    if (enrollingId != null) {
      // Keep the autoDispose enrollment provider alive while the request is
      // in flight — otherwise it can be disposed before the API returns.
      ref.watch(seriesEnrollmentProvider(enrollingId));
    }

    final locale = Localizations.localeOf(context);
    final lineHeight = getLineHeight(locale.languageCode);
    final profile = _resolveProfile();
    final isDark = widget.isDark;

    final orderedLinks = GroupProfileLinkUtils.orderedLinks(
      profile.socialLinks,
    );

    if (_isCommunityGroup(profile)) {
      return _buildCommunityProfileBody(
        profile,
        isDark,
        lineHeight,
        orderedLinks,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasBanner(profile)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProfileBanner(profile, isDark),
          ),
          const SizedBox(height: 14),
        ],
        _buildProfileHeader(profile, isDark, lineHeight, orderedLinks),
        const SizedBox(height: 20),
        Expanded(child: _buildDescriptionLongContent(profile)),
      ],
    );
  }

  Widget _buildCommunityProfileBody(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
    List<GroupProfileSocialLink> orderedLinks,
  ) {
    return NestedScrollView(
      headerSliverBuilder:
          (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasBanner(profile)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildProfileBanner(profile, isDark),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildProfileHeader(profile, isDark, lineHeight, orderedLinks),
                  const SizedBox(height: 20),
                  _GroupFollowButton(profile: profile, isDark: isDark),
                  const SizedBox(height: 24),
                  _buildTabBar(isDark, profile),
                ],
              ),
            ),
          ],
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildEmptyTab('No posts yet', isDark, lineHeight),
          GroupProfileEventsTab(
            groupId: profile.id,
            isDark: isDark,
            lineHeight: lineHeight,
          ),
          _buildPracticesTab(profile, isDark, lineHeight),
          GroupProfileMembersTab(
            groupId: profile.id,
            groupType: profile.groupType,
            isDark: isDark,
            lineHeight: lineHeight,
          ),
        ],
      ),
    );
  }

  GroupProfile _resolveProfile() {
    final freshProfile = ref.watch(groupProfileProvider(widget.profile.id));
    return freshProfile.maybeWhen(
      data:
          (either) => either.fold((_) => widget.profile, (profile) => profile),
      orElse: () => widget.profile,
    );
  }

  bool? _seriesGroupEnrollmentStatus(GroupProfileSeries series) {
    return seriesGroupEnrollmentStatus(
      series,
      localEnrolledSeriesIds: _localGroupEnrolledSeriesIds,
    );
  }

  Widget _buildProfileHeader(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
    List<GroupProfileSocialLink> orderedLinks,
  ) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final memberCount = profile.memberOrFollowerCount;
    final memberLabel =
        profile.groupType.isPage
            ? (memberCount == 1
                ? context.l10n.group_follower
                : context.l10n.group_followers)
            : (memberCount == 1
                ? context.l10n.group_member
                : context.l10n.group_members);
    final formattedCount = _formatCompactCount(
      memberCount,
      intlFormatLocaleOf(context),
    );
    final countLabel =
        context.isTibetanLocale
            ? '$memberLabel ${toTibetanDigits(formattedCount)}'
            : '$formattedCount $memberLabel';
    final aboutDescription =
        _isCommunityGroup(profile) ? _aboutDescription(profile) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child:
                      profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageWidget(
                            key: ValueKey(profile.avatarUrl),
                            imageUrl: profile.avatarUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: _buildAvatarFallback(isDark),
                          )
                          : _buildAvatarFallback(isDark),
                ),
              ),
              const SizedBox(width: 12),
              if (profile.title.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          height: lineHeight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                          height: lineHeight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (aboutDescription != null) ...[
            const SizedBox(height: 8),
            _buildHeaderAboutDescription(
              profile,
              aboutDescription,
              orderedLinks,
              isDark,
              lineHeight,
            ),
          ] else if (orderedLinks.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLinksEntryRow(profile, orderedLinks, isDark, lineHeight),
          ] else if (profile.subTitle != null &&
              profile.subTitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.subTitle!,
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                height: lineHeight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderAboutDescription(
    GroupProfile profile,
    String description,
    List<GroupProfileSocialLink> orderedLinks,
    bool isDark,
    double? lineHeight,
  ) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final actionColor = isDark ? AppColors.grey500 : AppColors.grey500;

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = TextStyle(
          fontSize: 13,
          color: secondaryColor,
          height: lineHeight,
        );

        final textSpan = TextSpan(text: description, style: style);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 2,
          textDirection: Directionality.of(context),
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        void openAboutScreen() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupAboutScreen(
                title: profile.title,
                description: description,
                links: orderedLinks,
              ),
            ),
          );
        }

        _moreRecognizer.onTap = openAboutScreen;

        final moreTapSpan = TextSpan(
          text: context.l10n.more,
          style: style.copyWith(
            color: actionColor,
            fontWeight: FontWeight.w500,
          ),
          recognizer: _moreRecognizer,
        );

        // Description fits within the collapsed height, but if there are
        // links to show, keep a "more" affordance so users can still reach
        // the About screen where those links live.
        if (!textPainter.didExceedMaxLines) {
          if (orderedLinks.isEmpty) {
            return Text.rich(textSpan);
          }
          return Text.rich(
            TextSpan(
              text: description,
              style: style,
              children: [const TextSpan(text: '  '), moreTapSpan],
            ),
          );
        }

        final moreSpan = TextSpan(
          text: '... ',
          style: style,
          children: [moreTapSpan],
        );

        int endIndex = description.length;
        int startIndex = 0;

        while (startIndex < endIndex) {
          int mid = startIndex + ((endIndex - startIndex) ~/ 2);
          final testSpan = TextSpan(
            text: description.substring(0, mid),
            style: style,
            children: [moreSpan],
          );
          final testPainter = TextPainter(
            text: testSpan,
            maxLines: 2,
            textDirection: Directionality.of(context),
          );
          testPainter.layout(maxWidth: constraints.maxWidth);

          if (testPainter.didExceedMaxLines) {
            endIndex = mid;
          } else {
            startIndex = mid + 1;
          }
        }

        final validLength = (startIndex - 1).clamp(0, description.length);
        final truncatedText = description.substring(0, validLength).trimRight();

        return Text.rich(
          TextSpan(
            text: truncatedText,
            style: style,
            children: [moreSpan],
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(bool isDark) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.usersThree,
        size: 22,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }

  Widget _buildLinksEntryRow(
    GroupProfile profile,
    List<GroupProfileSocialLink> links,
    bool isDark,
    double? lineHeight,
  ) {
    final primaryLink = links.first;
    final moreCount = links.length - 1;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupAboutScreen(
              title: profile.title,
              links: links,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(AppAssets.linkSimple, size: 18, color: secondaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                  height: lineHeight,
                ),
                children: [
                  TextSpan(text: primaryLink.url),
                  if (moreCount > 0)
                    TextSpan(
                      text:
                          ' ${context.l10n.group_and_more_links(moreCount)}',
                      style: TextStyle(color: secondaryColor),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark, GroupProfile profile) {
    final labelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey300;
    final membersTabLabel =
        profile.groupType.isPage
            ? context.l10n.group_tab_followers
            : context.l10n.group_tab_members;

    return Column(
      children: [
        TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: labelColor,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            const Tab(text: 'Post'),
            const Tab(text: 'Events'),
            Tab(text: context.l10n.tab_practices),
            Tab(text: membersTabLabel),
          ],
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }

  Widget _buildPracticesTab(
    GroupProfile profile,
    bool isDark,
    double? lineHeight,
  ) {
    final accumulatorsAsync = ref.watch(groupAccumulatorsProvider(profile.id));
    final series = profile.series;

    return accumulatorsAsync.when(
      data: (either) {
        final accumulators = either.fold(
          (_) => <GroupAccumulator>[],
          (page) => page.accumulators,
        );

        if (series.isEmpty && accumulators.isEmpty) {
          return const SizedBox.shrink();
        }

        final itemCount = series.length + accumulators.length;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final isLast = index == itemCount - 1;
            if (index < series.length) {
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: _buildSeriesCard(
                  profile,
                  series[index],
                  isDark,
                  lineHeight,
                ),
              );
            }

            final accumulator = accumulators[index - series.length];
            final localJoinedIds = ref.watch(
              groupAccumulatorJoinCacheProvider(profile.id),
            );
            final hasJoined = accumulatorHasJoined(
              accumulator,
              localJoinedIds: localJoinedIds,
            );
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: GroupAccumulatorCard(
                accumulator: accumulator,
                hasJoined: hasJoined,
                isDark: isDark,
                lineHeight: lineHeight,
                isJoining: _joiningAccumulatorId == accumulator.id,
                onTap: () => _navigateToAccumulatorDetail(accumulator.id),
                onJoinTap: () => _onJoinAccumulatorTap(profile, accumulator),
              ),
            );
          },
        );
      },
      loading: () {
        if (series.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: series.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == series.length - 1 ? 0 : 16,
              ),
              child: _buildSeriesCard(
                profile,
                series[index],
                isDark,
                lineHeight,
              ),
            );
          },
        );
      },
      error: (_, __) {
        if (series.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: series.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == series.length - 1 ? 0 : 16,
              ),
              child: _buildSeriesCard(
                profile,
                series[index],
                isDark,
                lineHeight,
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToAccumulatorDetail(String accumulatorId) {
    context.push(
      '/home/group-accumulator/$accumulatorId',
      extra: {'groupTitle': _resolveProfile().title},
    );
  }

  Future<void> _onJoinAccumulatorTap(
    GroupProfile profile,
    GroupAccumulator accumulator,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _joiningAccumulatorId = accumulator.id);
    final ok = await joinGroupAccumulator(
      ref: ref,
      accumulatorId: accumulator.id,
      groupId: profile.id,
      group: profile,
      awaitRefresh: false,
    );

    if (!mounted) return;
    setState(() => _joiningAccumulatorId = null);

    if (ok) {
      _navigateToAccumulatorDetail(accumulator.id);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.group_accumulator_join_error),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildProfileBanner(GroupProfile profile, bool isDark) {
    if (!_hasBanner(profile)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 3.5,
          child: CachedNetworkImageWidget(
            key: ValueKey(profile.bannerUrl),
            imageUrl: profile.bannerUrl,
            fit: BoxFit.cover,
            errorWidget: Container(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTab(String message, bool isDark, double? lineHeight) {
    final color = isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Center(
      child: Text(
        message,
        style: TextStyle(fontSize: 14, color: color, height: lineHeight),
      ),
    );
  }

  Widget _buildDescriptionLongContent(GroupProfile profile) {
    final content = _aboutDescription(profile);
    if (content == null) {
      return const SizedBox.shrink();
    }

    final bodyFontSize = getLocalizedFontSize(AppTextSize.body);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: PlanInlineMarkdownView(
        content: content,
        fontSize: bodyFontSize,
      ),
    );
  }

  String _formatCompactCount(int count, String locale) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}M';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}k';
    }
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }

  Widget _buildSeriesCard(
    GroupProfile profile,
    GroupProfileSeries series,
    bool isDark,
    double? lineHeight,
  ) {
    final dateRange = _formatSeriesDateRange(series);
    final enrollmentStatus = _seriesGroupEnrollmentStatus(series);
    final showPracticeOverlay = enrollmentStatus != true;
    final isEnrolling = _enrollingSeriesId == series.id;
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;

    return Material(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            isEnrolling ? null : () => _navigateToSeriesDetail(profile, series),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  series.image != null && !series.image!.isEmpty
                      ? ResponsiveCoverImage(
                        image: series.image,
                        fit: BoxFit.cover,
                      )
                      : ColoredBox(
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.grey100,
                        child: Icon(
                          AppAssets.bookOpenText,
                          size: 40,
                          color: isDark ? AppColors.grey500 : AppColors.grey600,
                        ),
                      ),
                  if (showPracticeOverlay)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child:
                          isEnrolling
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap:
                                    () => _onPracticeWithUsTap(profile, series),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    context.l10n.group_practice_with_us,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: lineHeight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dateRange != null || series.enrolledCount > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (dateRange != null)
                          Expanded(
                            child: Text(
                              dateRange,
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryColor,
                                height: lineHeight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (series.enrolledCount > 0) ...[
                          Icon(
                            AppAssets.usercard,
                            size: 16,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${series.enrolledCount}',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                              height: lineHeight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _formatSeriesDateRange(GroupProfileSeries series) {
    return PlanDateFormat.formatRangeOrNull(series.startDate, series.endDate);
  }

  void _navigateToSeriesDetail(
    GroupProfile profile,
    GroupProfileSeries series,
  ) {
    widget.onSeriesTap?.call();
    if (_seriesGroupEnrollmentStatus(series) == true) {
      context.push('/home/series/${series.id}');
      return;
    }

    context.push(
      '/home/series/${series.id}',
      extra: {
        'groupId': profile.id,
        'groupType': profile.groupType,
        'isGroupEnrolled': false,
      },
    );
  }

  Future<void> _onPracticeWithUsTap(
    GroupProfile profile,
    GroupProfileSeries series,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final enrollmentStatus = _seriesGroupEnrollmentStatus(series);
    final confirmed = await confirmGroupPracticeChangeIfNeeded(
      context,
      enrollmentStatus,
    );
    if (!confirmed || !mounted) return;

    setState(() => _enrollingSeriesId = series.id);

    final ok = await enrollSeriesThroughGroup(
      ref: ref,
      seriesId: series.id,
      groupId: profile.id,
      groupType: profile.groupType,
    );

    if (!mounted) return;
    setState(() {
      _enrollingSeriesId = null;
      if (ok) _localGroupEnrolledSeriesIds.add(series.id);
    });

    if (ok) {
      await ref.read(groupProfileProvider(profile.id).future);
      if (!mounted) return;
      await context.pushNamed(
        'edit-routine',
        extra: {'enrollSeriesId': series.id},
      );
      if (!mounted) return;
      await completeGroupPracticeEnrollmentFlow(
        ref: ref,
        groupId: profile.id,
        groupType: profile.groupType,
      );
      return;
    }

    final state = ref.read(seriesEnrollmentProvider(series.id));
    final message =
        state is SeriesEnrollmentFailure
            ? state.failure.message
            : context.l10n.series_enroll_error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

}

class _GroupFollowButton extends ConsumerWidget {
  final GroupProfile profile;
  final bool isDark;

  const _GroupFollowButton({required this.profile, required this.isDark});

  Future<void> _onInvitePressed(BuildContext context) async {
    final shareUrl =
        DeepLinkUrlBuilder.groupLink(groupId: profile.id).toString();
    final shareMessage = context.l10n.share_group_invite_message;
    final sharePositionOrigin = getSharePositionOrigin(context: context);
    await SharePlus.instance.share(
      ShareParams(
        text: '$shareMessage\n\n$shareUrl',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followKey = GroupFollowKey(
      groupId: profile.id,
      groupType: profile.groupType,
    );
    final followState = ref.watch(groupFollowProvider(followKey));

    final isFollowing = switch (followState) {
      GroupFollowSuccess(isFollowing: final f) => f,
      _ => false,
    };
    final isLoading = followState is GroupFollowLoading;
    final isPage = profile.groupType.isPage;
    const fontSize = 16.0;
    final locale = Localizations.localeOf(context);
    final isTibetan = context.isTibetanLocale;
    final buttonHeight = isTibetan ? 52.0 : 48.0;
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(0, buttonHeight),
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: isTibetan ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child:
          isFollowing
              ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () => _onFollowPressed(
                                context,
                                ref,
                                followKey,
                                isFollowing,
                              ),
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.grey100,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                isPage
                                    ? context.l10n.following
                                    : context.l10n.joined,
                                textAlign: TextAlign.center,
                                strutStyle: context.tibetanStrutStyle(fontSize),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: getSystemFontFamily(
                                    locale.languageCode,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _onInvitePressed(context),
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          isDark
                              ? AppColors.textPrimary
                              : AppColors.surfaceWhite,
                        ),
                      ),
                      child: Text(
                        context.l10n.group_invite,
                        textAlign: TextAlign.center,
                        strutStyle: context.tibetanStrutStyle(fontSize),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: getSystemFontFamily(locale.languageCode),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () => _onFollowPressed(
                            context,
                            ref,
                            followKey,
                            isFollowing,
                          ),
                  style: buttonStyle.copyWith(
                    backgroundColor: WidgetStatePropertyAll(
                      isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      isDark ? AppColors.textPrimary : AppColors.surfaceWhite,
                    ),
                    minimumSize: WidgetStatePropertyAll(
                      Size(double.infinity, buttonHeight),
                    ),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            isPage ? context.l10n.follow : context.l10n.join,
                            textAlign: TextAlign.center,
                            strutStyle: context.tibetanStrutStyle(fontSize),
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              fontFamily: getSystemFontFamily(
                                locale.languageCode,
                              ),
                            ),
                          ),
                ),
              ),
    );
  }

  Future<void> _onFollowPressed(
    BuildContext context,
    WidgetRef ref,
    GroupFollowKey followKey,
    bool isCurrentlyFollowing,
  ) async {
    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    final notifier = ref.read(groupFollowProvider(followKey).notifier);
    isCurrentlyFollowing
        ? await notifier.unfollow(connectGroup: profile)
        : await notifier.follow(connectGroup: profile);
  }
}
