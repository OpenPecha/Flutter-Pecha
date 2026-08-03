import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/error/error_message_mapper.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/chat_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/thread_list_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/delete_thread_dialog.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/skeletons/chat_thread_skeleton.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/thread_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

class ChatHistoryDrawer extends ConsumerStatefulWidget {
  const ChatHistoryDrawer({super.key});

  @override
  ConsumerState<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends ConsumerState<ChatHistoryDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load threads with smart caching when drawer opens
    // Uses sliding window: 5min idle, 1hr max lifetime
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(threadListControllerProvider.notifier).loadThreads();
      // Record that user opened drawer (interaction)
      ref.read(threadListControllerProvider.notifier).recordInteraction();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Record interaction when user scrolls (resets idle timer)
    ref.read(threadListControllerProvider.notifier).recordInteraction();

    // Load more when user scrolls to 80% of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(threadListControllerProvider.notifier).loadMoreThreads();
    }
  }

  // Commented out until search functionality is implemented
  // void _performSearch(String query) {
  //   // Unfocus the text field
  //   _searchFocusNode.unfocus();
  //   // TODO: Implement search functionality with query
  //   // For now, just print or handle the search
  //   if (query.trim().isNotEmpty) {
  //     // Add your search logic here
  //     debugPrint('Searching for: $query');
  //   }
  // }

  Future<void> _handleDeleteThread(String threadId, String threadTitle) async {
    // Unfocus any focused widget
    _searchFocusNode.unfocus();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteThreadDialog(threadTitle: threadTitle),
    );

    // If user confirmed deletion
    if (confirmed == true && mounted) {
      try {
        // Get current thread ID before deletion
        final currentThreadId =
            ref.read(chatControllerProvider).currentThreadId;
        final isCurrentThread = currentThreadId == threadId;

        // Delete the thread
        await ref
            .read(threadListControllerProvider.notifier)
            .deleteThread(threadId);

        // If the deleted thread was the active one, start a new thread
        if (isCurrentThread) {
          ref.read(chatControllerProvider.notifier).startNewThread();
        }

        // Show success message
        if (mounted) {
          final localizations = context.l10n;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.ai_chat_deleted,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
            e,
            context: 'delete',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendlyMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final threadListState = ref.watch(threadListControllerProvider);
    final currentThreadId = ref.watch(chatControllerProvider).currentThreadId;
    final screenWidth = MediaQuery.of(context).size.width;
    // Drawer width: 85% of screen, max 320
    final drawerWidth = (screenWidth * 0.85).clamp(280.0, 320.0);

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside the text field
            _searchFocusNode.unfocus();
          },
          onHorizontalDragEnd: (details) {
            // Close drawer when swiping from right to left
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -300) {
              Navigator.of(context).pop();
            }
          },
          child: SizedBox(
            width: drawerWidth,
            height: double.infinity,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Field
                        // TextField(
                        //   controller: _searchController,
                        //   focusNode: _searchFocusNode,
                        //   textInputAction: TextInputAction.search,
                        //   decoration: InputDecoration(
                        //     hintText: context.l10n.ai_search_chats,
                        //     hintStyle: TextStyle(
                        //       fontSize: 12,
                        //       color:
                        //           isDarkMode
                        //               ? AppColors.grey500
                        //               : AppColors.textPrimaryLight,
                        //     ),
                        //     prefixIcon: Icon(
                        //       Icons.search,
                        //       color:
                        //           isDarkMode
                        //               ? AppColors.textPrimaryDark
                        //               : AppColors.textPrimary,
                        //       size: 28,
                        //     ),
                        //     filled: true,
                        //     fillColor:
                        //         isDarkMode
                        //             ? AppColors.surfaceDark
                        //             : AppColors.textPrimaryDark,
                        //     contentPadding: const EdgeInsets.symmetric(
                        //       vertical: 12,
                        //       horizontal: 16,
                        //     ),
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(20),
                        //       borderSide: BorderSide.none,
                        //     ),
                        //     enabledBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(20),
                        //       borderSide: BorderSide.none,
                        //     ),
                        //     focusedBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(20),
                        //       borderSide: BorderSide(
                        //         color: AppColors.accentGold,
                        //         width: 1.5,
                        //       ),
                        //     ),
                        //   ),
                        //   style: TextStyle(
                        //     fontSize: 11,
                        //     color:
                        //         isDarkMode
                        //             ? AppColors.surfaceWhite
                        //             : AppColors.textPrimary,
                        //   ),
                        //   onChanged: (value) {
                        //     // TODO: Implement real-time search filtering
                        //   },
                        //   onSubmitted: _performSearch,
                        // ),
                        // const SizedBox(height: 16),
                        // Chats Header with New Chat Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.ai_chats,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            // New Chat Icon
                            GestureDetector(
                              onTap: () {
                                // Unfocus any focused widget before performing actions
                                FocusScope.of(context).unfocus();
                                ref
                                    .read(chatControllerProvider.notifier)
                                    .startNewThread();
                                ref
                                    .read(threadListControllerProvider.notifier)
                                    .refreshThreads();
                                Navigator.of(context).pop(); // Close drawer
                              },
                              child: Icon(Icons.add, size: 24),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 5),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  // Thread List
                  Expanded(
                    child: _buildThreadList(
                      isDarkMode,
                      threadListState,
                      currentThreadId,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreadList(
    bool isDarkMode,
    ThreadListState state,
    String? currentThreadId,
  ) {
    if (state.isLoading) {
      return const ChatThreadSkeleton();
    }

    if (state.error != null) {
      final localizations = context.l10n;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: isDarkMode ? AppColors.error : AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Use loadThreads() instead of refreshThreads() for retry
                  // This respects the cache and only reloads if needed
                  ref.read(threadListControllerProvider.notifier).loadThreads();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGoldDarkest,
                  foregroundColor: Colors.white,
                ),
                child: Text(localizations.ai_retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.threads.isEmpty) {
      final localizations = context.l10n;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: isDarkMode ? AppColors.grey800 : AppColors.grey300,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.ai_no_conversations,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.ai_start_new_chat,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Manual refresh - force reload regardless of cache state
        await ref.read(threadListControllerProvider.notifier).refreshThreads();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.threads.length + (state.isLoadingMore ? 1 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == state.threads.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accentGold,
                  ),
                ),
              ),
            );
          }

          final thread = state.threads[index];
          final isActive = thread.id == currentThreadId;

          return ThreadListItem(
            thread: thread,
            isActive: isActive,
            onTap: () {
              // Haptic feedback for better tactile response
              HapticFeedback.lightImpact();

              // Unfocus to prevent keyboard popup
              FocusScope.of(context).unfocus();

              // Record interaction before loading thread (resets idle timer)
              ref
                  .read(threadListControllerProvider.notifier)
                  .recordInteraction();

              Navigator.of(context).pop();

              // Load the selected thread in background
              ref.read(chatControllerProvider.notifier).loadThread(thread.id);
            },
            onDelete: () => _handleDeleteThread(thread.id, thread.title),
          );
        },
      ),
    );
  }
}
