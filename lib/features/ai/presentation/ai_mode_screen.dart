import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/chat_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/thread_list_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/chat_header.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/chat_history_drawer.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/message_list.dart';
import 'package:flutter_pecha/features/ai/validators/message_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';

class AiModeScreen extends ConsumerStatefulWidget {
  const AiModeScreen({super.key});

  @override
  ConsumerState<AiModeScreen> createState() => _AiModeScreenState();
}

class _AiModeScreenState extends ConsumerState<AiModeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _suggestions = [
    'What is self ?',
    'How one can attain enlightenment ?',
  ];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Always rebuild to update character counter
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSuggestionTap(String suggestion) {
    // Don't focus the text field when tapping suggestions
    _sendMessage(suggestion);
  }

  void _onSendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final message = _controller.text.trim();
    _controller.clear();
    _focusNode.unfocus();
    _sendMessage(message);
  }

  void _sendMessage(String message) {
    ref.read(chatControllerProvider.notifier).sendMessage(message);
  }

  void _onNewChat() {
    // Start new thread
    ref.read(chatControllerProvider.notifier).startNewThread();
    // Refresh thread list to show the new thread (when API is integrated)
    ref.read(threadListControllerProvider.notifier).refreshThreads();
  }

  void _onMenuPressed() {
    // Show fullscreen overlay drawer that covers bottom nav
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chat History',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const ChatHistoryDrawer();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    if (authState.isGuest) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildSignInPrompt(isDarkMode),
      );
    }

    final chatState = ref.watch(chatControllerProvider);
    final hasMessages = chatState.messages.isNotEmpty || chatState.isStreaming;

    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${chatState.error}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ref.read(chatControllerProvider.notifier).clearError();
              },
            ),
          ),
        );
        ref.read(chatControllerProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        onHorizontalDragEnd: (details) {
          // Open drawer when swiping from left to right
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            _onMenuPressed();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Show full header when in chat mode, minimal header in empty state
              if (hasMessages)
                ChatHeader(onNewChat: _onNewChat, onMenuPressed: _onMenuPressed)
              else
                _buildMinimalHeader(isDarkMode),

              // Main content area
              Expanded(
                child:
                    chatState.isLoadingThread
                        ? _buildLoadingState(isDarkMode)
                        : hasMessages
                        ? MessageList(
                          messages: chatState.messages,
                          isStreaming: chatState.isStreaming,
                          currentStreamingContent:
                              chatState.currentStreamingContent,
                        )
                        : _buildEmptyState(isDarkMode),
              ),

              // Bottom input section
              _buildInputSection(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  // Build the minimal header for the empty state. Starting State for the app.
  Widget _buildMinimalHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _onMenuPressed,
            icon: Icon(
              Icons.menu_sharp,
              color:
                  isDarkMode
                      ? AppColors.surfaceWhite
                      : AppColors.cardBorderDark,
            ),
            tooltip: 'Chat History',
          ),
          Text(
            'Buddhist AI Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color:
                  isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
            ),
          ),
          // Invisible spacer to balance the layout
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading conversation...',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(bool isDarkMode) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? AppColors.surfaceWhite
                          : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please sign in to access the Buddhist AI Assistant and start meaningful conversations',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                onPressed: () {
                  LoginDrawer.show(context, ref);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Explore Buddhist Wisdom',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.surfaceWhite : Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children:
                    _suggestions.map((s) {
                      return InkWell(
                        onTap: () => _onSuggestionTap(s),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 15,
                                color:
                                    isDarkMode
                                        ? AppColors.surfaceWhite
                                        : AppColors.grey800,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s,
                                style: TextStyle(
                                  fontSize: 12,
                                  // fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode
                                          ? AppColors.surfaceWhite
                                          : AppColors.grey800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isDarkMode) {
    final textLength = _controller.text.length;
    final isOverLimit = MessageValidator.exceedsLimit(_controller.text);
    final isApproachingLimit = MessageValidator.isApproachingLimit(
      _controller.text,
    );
    final canSend = _hasText && !isOverLimit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppColors.surfaceVariantDark
                      : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: false,
                    enableInteractiveSelection: true,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask a question ...',
                      hintStyle: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textSubtleDark
                                : AppColors.textPrimaryLight,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: IconButton(
                    onPressed: canSend ? _onSendMessage : null,
                    icon: Icon(
                      Icons.send_rounded,
                      color:
                          canSend
                              ? (isDarkMode
                                  ? AppColors.primaryContainer
                                  : AppColors.backgroundDark)
                              : (isDarkMode
                                  ? AppColors.grey500
                                  : AppColors.grey800),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Character counter - only show when user has typed something
          if (_hasText)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$textLength/${MessageValidator.maxLength}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isOverLimit
                            ? Colors.red
                            : isApproachingLimit
                            ? Colors.orange
                            : (isDarkMode
                                ? AppColors.grey500
                                : AppColors.grey600),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }
}
