import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_posts_providers.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_post_card.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_empty_state.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Posts tab content with My / Discover sub-tabs.
class ConnectPostsTab extends ConsumerStatefulWidget {
  const ConnectPostsTab({super.key});

  @override
  ConsumerState<ConnectPostsTab> createState() => _ConnectPostsTabState();
}

class _ConnectPostsTabState extends ConsumerState<ConnectPostsTab> {
  int _selectedSegment = 0;
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _discoverScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _myScrollController.addListener(_onMyScroll);
    _discoverScrollController.addListener(_onDiscoverScroll);
  }

  @override
  void dispose() {
    _myScrollController.removeListener(_onMyScroll);
    _discoverScrollController.removeListener(_onDiscoverScroll);
    _myScrollController.dispose();
    _discoverScrollController.dispose();
    super.dispose();
  }

  void _onMyScroll() => _onScroll(_myScrollController, myConnectPostsProvider);

  void _onDiscoverScroll() =>
      _onScroll(_discoverScrollController, discoverConnectPostsProvider);

  void _onScroll(
    ScrollController controller,
    StateNotifierProvider<ConnectPostsNotifier, ConnectPostsState> provider,
  ) {
    if (!controller.hasClients) return;
    if (controller.position.pixels <
        controller.position.maxScrollExtent - 200) {
      return;
    }
    ref.read(provider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final myState = ref.watch(myConnectPostsProvider);
    final discoverState = ref.watch(discoverConnectPostsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ConnectSegmentedControl(
            segments: const ['My', 'Discover'],
            selectedIndex: _selectedSegment,
            onChanged: (index) => setState(() => _selectedSegment = index),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedSegment,
            children: [
              RefreshIndicator(
                onRefresh:
                    () => ref.read(myConnectPostsProvider.notifier).refresh(),
                child: _buildPostsList(
                  context,
                  myState,
                  scrollController: _myScrollController,
                  includeUnfollowed: false,
                  isMySegment: true,
                  onRetry: () => ref.read(myConnectPostsProvider.notifier).retry(),
                  onBrowseDiscover: () => setState(() => _selectedSegment = 1),
                ),
              ),
              RefreshIndicator(
                onRefresh:
                    () =>
                        ref.read(discoverConnectPostsProvider.notifier).refresh(),
                child: _buildPostsList(
                  context,
                  discoverState,
                  scrollController: _discoverScrollController,
                  includeUnfollowed: true,
                  isMySegment: false,
                  onRetry:
                      () => ref.read(discoverConnectPostsProvider.notifier).retry(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList(
    BuildContext context,
    ConnectPostsState postsState, {
    required ScrollController scrollController,
    required bool includeUnfollowed,
    required bool isMySegment,
    required VoidCallback onRetry,
    VoidCallback? onBrowseDiscover,
  }) {
    if (postsState.isLoading && postsState.posts.isEmpty) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (postsState.error != null && postsState.posts.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: ErrorStateWidget(
              error: postsState.error!,
              onRetry: onRetry,
            ),
          ),
        ],
      );
    }

    if (postsState.posts.isEmpty && !postsState.isLoading) {
      if (isMySegment && onBrowseDiscover != null) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ConnectMyEmptyState(
                type: ConnectMyEmptyStateType.posts,
                onBrowseTap: onBrowseDiscover,
              ),
            ),
          ],
        );
      }

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text(
                'No posts to discover',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: postsState.posts.length + (postsState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == postsState.posts.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  postsState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final post = postsState.posts[index];
        return ConnectPostCard(
          post: post,
          includeUnfollowed: includeUnfollowed,
        );
      },
    );
  }
}
