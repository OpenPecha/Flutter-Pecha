import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/chat_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/thread_list_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/delete_thread_dialog.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/thread_list_item.dart';
import 'package:flutter_pecha/features/auth/application/user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Load threads when drawer is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(threadListControllerProvider.notifier).loadThreads();
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
    // Load more when user scrolls to 80% of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(threadListControllerProvider.notifier).loadMoreThreads();
    }
  }

  void _performSearch(String query) {
    // Unfocus the text field
    _searchFocusNode.unfocus();
    // TODO: Implement search functionality with query
    // For now, just print or handle the search
    if (query.trim().isNotEmpty) {
      // Add your search logic here
      debugPrint('Searching for: $query');
    }
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Chat Deleted',
                      style: TextStyle(
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete conversation: ${e.toString()}'),
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
    final userState = ref.watch(userProvider);

    return Drawer(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.primarySurface,
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside the text field
          _searchFocusNode.unfocus();
        },
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
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search for chats',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? AppColors.grey500
                                  : AppColors.textPrimaryLight,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                          size: 28,
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode
                                ? AppColors.surfaceDark
                                : AppColors.textPrimaryDark,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDarkMode
                                ? AppColors.surfaceWhite
                                : AppColors.textPrimary,
                      ),
                      onChanged: (value) {
                        // TODO: Implement real-time search filtering
                      },
                      onSubmitted: _performSearch,
                    ),
                    const SizedBox(height: 16),
                    // Chats Header with New Chat Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chats',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color:
                                isDarkMode
                                    ? AppColors.surfaceWhite
                                    : AppColors.textPrimary,
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
                          child: Icon(
                            Icons.add,
                            size: 24,
                            color:
                                isDarkMode
                                    ? AppColors.surfaceWhite
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    // const SizedBox(height: 5),
                  ],
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 5),
              // Thread List or Guest Message
              Expanded(
                child:
                    userState.isAuthenticated
                        ? _buildThreadList(
                          isDarkMode,
                          threadListState,
                          currentThreadId,
                        )
                        : _buildGuestMessage(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestMessage(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: isDarkMode ? AppColors.grey800 : AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view chat history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.grey400 : AppColors.grey800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to save and access your conversations across devices',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null) {
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
                'Failed to load conversations',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(threadListControllerProvider.notifier)
                      .refreshThreads();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkest,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.threads.isEmpty) {
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
                'No conversations yet',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a new chat to begin',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.threads.length + (state.isLoadingMore ? 1 : 0),
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
                  color: AppColors.primary,
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
          onTap: () async {
            // Unfocus to prevent keyboard popup
            FocusScope.of(context).unfocus();
            // Load the selected thread
            await ref
                .read(chatControllerProvider.notifier)
                .loadThread(thread.id);
            // Refresh threads to update order
            ref.read(threadListControllerProvider.notifier).refreshThreads();
            // Close drawer
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          onDelete: () => _handleDeleteThread(thread.id, thread.title),
        );
      },
    );
  }
}
