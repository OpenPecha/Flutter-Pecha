import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/chat_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/thread_list_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/thread_list_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatHistoryDrawer extends ConsumerStatefulWidget {
  const ChatHistoryDrawer({super.key});

  @override
  ConsumerState<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends ConsumerState<ChatHistoryDrawer> {
  @override
  void initState() {
    super.initState();
    // Load threads when drawer is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(threadListControllerProvider.notifier).loadThreads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final threadListState = ref.watch(threadListControllerProvider);
    final currentThreadId = ref.watch(chatControllerProvider).currentThreadId;

    return Drawer(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.surfaceWhite,
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
                  Center(
                    child: Text(
                      'Chats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // New Chat Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Unfocus any focused widget before performing actions
                        FocusScope.of(context).unfocus();
                        ref.read(chatControllerProvider.notifier).startNewThread();
                        ref.read(threadListControllerProvider.notifier).refreshThreads();
                        Navigator.of(context).pop(); // Close drawer
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Chat', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 5),
            // Thread List
            Expanded(
              child: _buildThreadList(isDarkMode, threadListState, currentThreadId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadList(bool isDarkMode, ThreadListState state, String? currentThreadId) {
    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load conversations',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(threadListControllerProvider.notifier).refreshThreads();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
      itemCount: state.threads.length,
      itemBuilder: (context, index) {
        final thread = state.threads[index];
        final isActive = thread.id == currentThreadId;

        return ThreadListItem(
          thread: thread,
          isActive: isActive,
          onTap: () async {
            // Unfocus to prevent keyboard popup
            FocusScope.of(context).unfocus();
            // Load the selected thread
            await ref.read(chatControllerProvider.notifier).loadThread(thread.id);
            // Close drawer
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }
}

