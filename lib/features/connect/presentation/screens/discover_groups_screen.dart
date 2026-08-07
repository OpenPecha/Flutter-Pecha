import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/discover_group_card.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoverGroupsScreen extends ConsumerStatefulWidget {
  const DiscoverGroupsScreen({super.key});

  @override
  ConsumerState<DiscoverGroupsScreen> createState() =>
      _DiscoverGroupsScreenState();
}

class _DiscoverGroupsScreenState extends ConsumerState<DiscoverGroupsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoverGroupsProvider.notifier).ensureLoaded();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(discoverGroupsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverGroupsProvider);
    final myGroupsAsync = ref.watch(myGroupsProvider);
    final pendingGroups = ref.watch(pendingJoinedGroupsProvider);
    final pendingUnjoinedIds = ref.watch(pendingUnjoinedGroupIdsProvider);

    final apiGroups = myGroupsAsync.valueOrNull?.groups ?? const [];
    final displayedMyGroups = mergeMyGroupsWithPending(
      apiGroups: apiGroups,
      pendingGroups: pendingGroups,
      pendingUnjoinedIds: pendingUnjoinedIds,
    );
    final joinedGroupIds = displayedMyGroups.map((group) => group.id).toSet();
    final groups = filterDiscoverGroups(
      discoverGroups: discoverState.groups,
      joinedGroupIds: joinedGroupIds,
    );

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(context.l10n.discover_groups),
      ),
      body: _buildBody(context, discoverState, groups),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DiscoverGroupsState groupsState,
    List<GroupProfile> groups,
  ) {
    if (groupsState.isLoading && groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groupsState.error != null && groups.isEmpty) {
      return Center(
        child: ErrorStateWidget(
          error: groupsState.error!,
          onRetry: () => ref.read(discoverGroupsProvider.notifier).retry(),
          customMessage: context.l10n.connect_groups_load_error,
        ),
      );
    }

    if (groups.isEmpty && !groupsState.isLoading) {
      return Center(child: Text(context.l10n.connect_groups_empty_title));
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: groups.length + (groupsState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == groups.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  groupsState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        return DiscoverGroupCard(group: groups[index], showJoinButton: true);
      },
    );
  }
}
