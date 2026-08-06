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
  const ConnectPostsTab({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  ConsumerState<ConnectPostsTab> createState() => _ConnectPostsTabState();
}

class _ConnectPostsTabState extends ConsumerState<ConnectPostsTab> {
  int _selectedSegment = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      final provider =
          _selectedSegment == 0
              ? myConnectPostsProvider
              : discoverConnectPostsProvider;
      ref.read(provider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(
      _selectedSegment == 0
          ? myConnectPostsProvider
          : discoverConnectPostsProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ConnectSegmentedControl(
            segments: const ['My', 'Discover'],
            selectedIndex: _selectedSegment,
            onChanged: (index) {
              setState(() => _selectedSegment = index);
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await widget.onRefresh();
              final provider =
                  _selectedSegment == 0
                      ? myConnectPostsProvider
                      : discoverConnectPostsProvider;
              await ref.read(provider.notifier).refresh();
            },
            child: _buildPostsList(context, postsState),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsList(BuildContext context, ConnectPostsState postsState) {
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
              onRetry: () {
                final provider =
                    _selectedSegment == 0
                        ? myConnectPostsProvider
                        : discoverConnectPostsProvider;
                ref.read(provider.notifier).retry();
              },
            ),
          ),
        ],
      );
    }

    if (postsState.posts.isEmpty && !postsState.isLoading) {
      if (_selectedSegment == 0) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ConnectMyEmptyState(
                type: ConnectMyEmptyStateType.posts,
                onBrowseTap: () => setState(() => _selectedSegment = 1),
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
      controller: _scrollController,
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
          includeUnfollowed: _selectedSegment == 1,
        );
      },
    );
  }
}
