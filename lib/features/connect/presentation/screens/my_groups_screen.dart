import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyGroupsScreen extends ConsumerWidget {
  const MyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final pendingGroups = ref.watch(pendingJoinedGroupsProvider);
    final pendingUnjoinedIds = ref.watch(pendingUnjoinedGroupIdsProvider);
    final apiGroups = myGroupsAsync.valueOrNull?.groups ?? const [];
    final groups = mergeMyGroupsWithPending(
      apiGroups: apiGroups,
      pendingGroups: pendingGroups,
      pendingUnjoinedIds: pendingUnjoinedIds,
    );

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(context.l10n.my_groups),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppAssets.arrowLeft),
        ),
      ),
      body: myGroupsAsync.when(
        loading: () {
          if (groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildGroupsList(groups, isDark);
        },
        error: (error, _) => Center(child: Text('$error')),
        data: (_) => _buildGroupsList(groups, isDark),
      ),
    );
  }

  Widget _buildGroupsList(List<GroupProfile> groups, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _MyGroupListTile(group: groups[index], isDark: isDark);
      },
    );
  }
}

class _MyGroupListTile extends StatelessWidget {
  const _MyGroupListTile({required this.group, required this.isDark});

  final GroupProfile group;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/home/group/${group.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cardColor,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageWidget(imageUrl: group.avatarUrl!)
                          : ColoredBox(
                            color:
                                isDark
                                    ? AppColors.surfaceVariantDark
                                    : AppColors.grey100,
                            child: Icon(
                              AppAssets.usersThree,
                              size: 22,
                              color:
                                  isDark
                                      ? AppColors.grey500
                                      : AppColors.grey600,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                AppAssets.caretRight,
                size: 16,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final typeLabel =
        group.tags.isNotEmpty
            ? group.tags.first
            : (group.subTitle ?? group.groupType.name);
    final memberCount = group.joinerCount;
    final memberLabel =
        memberCount == 1
            ? context.l10n.group_member
            : context.l10n.group_members;

    return '$typeLabel · $memberCount $memberLabel';
  }
}
