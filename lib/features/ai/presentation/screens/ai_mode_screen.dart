import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/error/error_message_mapper.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/chat_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/search_state_controller.dart';
import 'package:flutter_pecha/features/ai/data/models/search_state.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/chat_header.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/chat_history_drawer.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/message_list.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/skeletons/chat_message_skeleton.dart';
import 'package:flutter_pecha/features/ai/validators/message_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:go_router/go_router.dart';

class AiModeScreen extends ConsumerStatefulWidget {
  const AiModeScreen({super.key});

  @override
  ConsumerState<AiModeScreen> createState() => _AiModeScreenState();
}

class _AiModeScreenState extends ConsumerState<AiModeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  // Mode selection: true = Search Mode, false = AI Mode
  bool _isSearchMode = true;

  /// Extract first name from user data
  /// Uses firstName if available, otherwise extracts first part of username
  String? _getFirstName() {
    final userState = ref.read(userProvider);
    final user = userState.user;

    if (user == null) return null;

    // Try firstName first
    if (user.firstName != null && user.firstName!.trim().isNotEmpty) {
      return user.firstName!.trim();
    }

    // Fallback to username (extract first part)
    if (user.username != null && user.username!.trim().isNotEmpty) {
      final usernameParts = user.username!.trim().split(' ');
      return usernameParts.first;
    }

    return null;
  }

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

  void _onSendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final message = _controller.text.trim();
    _controller.clear();
    _focusNode.unfocus();

    if (_isSearchMode) {
      // Navigate to search results screen
      context.push('/ai-mode/search-results', extra: {'query': message});
    } else {
      // AI Mode - send message to chat
      ref.read(chatControllerProvider.notifier).sendMessage(message);
    }
  }

  void _onNewChat() {
    // Start new thread
    ref.read(chatControllerProvider.notifier).startNewThread();
    // Note: Thread list will be refreshed automatically when we receive
    // the thread_id from the API after sending the first message
  }

  void _onMenuPressed() {
    // Show fullscreen overlay drawer that covers bottom nav
    final localizations = AppLocalizations.of(context)!;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: localizations.ai_chat_history,
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
    final isGuest = authState.isGuest;

    // Listen for flag to switch to AI mode when returning from search results
    ref.listen<SearchState>(searchStateProvider, (previous, next) {
      if (next.shouldSwitchToAiMode && _isSearchMode) {
        // Only switch to AI mode if user is authenticated
        if (!isGuest) {
          setState(() {
            _isSearchMode = false;
          });
        }
        // Clear the flag
        ref.read(searchStateProvider.notifier).setSwitchToAiMode(false);
      }
    });

    // Guests in AI mode should see sign-in prompt
    if (isGuest && !_isSearchMode) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildGuestAiModeView(isDarkMode),
      );
    }

    // For guests in search mode, don't load chat state
    final chatState = isGuest ? null : ref.watch(chatControllerProvider);
    final hasMessages = chatState != null && 
        (chatState.messages.isNotEmpty || chatState.isStreaming);

    final chatError = chatState?.error;
    if (chatError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final localizations = AppLocalizations.of(context)!;
        final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
          chatError,
          context: 'chat',
        );
        final isRetryable = ErrorMessageMapper.isRetryable(chatError);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label:
                  isRetryable
                      ? localizations.ai_retry
                      : localizations.ai_dismiss,
              textColor: Colors.white,
              onPressed: () {
                ref.read(chatControllerProvider.notifier).clearError();
              },
            ),
            duration: const Duration(seconds: 4),
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
                child: _buildMainContent(isDarkMode, isGuest, chatState),
              ),

              // Bottom input section
              _buildInputSection(isDarkMode, isGuest),
            ],
          ),
        ),
      ),
    );
  }

  // Build the minimal header for the empty state. Starting State for the app.
  Widget _buildMinimalHeader(bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
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
            tooltip: localizations.ai_chat_history,
          ),
          Text(
            localizations.ai_buddhist_assistant,
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
    return const ChatMessageSkeleton();
  }

  /// Build main content based on chat state
  Widget _buildMainContent(bool isDarkMode, bool isGuest, dynamic chatState) {
    if (chatState?.isLoadingThread == true) {
      return _buildLoadingState(isDarkMode);
    }

    final hasMessages = chatState != null &&
        (chatState.messages.isNotEmpty || chatState.isStreaming);

    if (hasMessages) {
      return MessageList(
        messages: chatState.messages,
        isStreaming: chatState.isStreaming,
        currentStreamingContent: chatState.currentStreamingContent,
      );
    }

    return _buildEmptyState(isDarkMode, isGuest);
  }

  Widget _buildEmptyState(bool isDarkMode, bool isGuest) {
    final localizations = AppLocalizations.of(context)!;
    final firstName = isGuest ? null : _getFirstName();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Personalized greeting (only for authenticated users)
            if (firstName != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  localizations.ai_greeting(firstName),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: isDarkMode ? AppColors.grey500 : AppColors.grey800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                localizations.ai_explore_wisdom,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppColors.surfaceWhite : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build view for guests who selected AI mode (requires sign in)
  Widget _buildGuestAiModeView(bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        children: [
          // Minimal header with mode switch
          _buildGuestHeader(isDarkMode),
          // Sign in prompt
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: AppColors.accentGold.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localizations.sign_in,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.surfaceWhite
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.ai_sign_in_prompt,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: Text(localizations.sign_in),
                      onPressed: () => LoginDrawer.show(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Option to switch to search mode
                    TextButton(
                      onPressed: () => setState(() => _isSearchMode = true),
                      child: Text(
                        AppLocalizations.of(context)!.ai_use_search_instead,
                        style: const TextStyle(
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header for guest AI mode view with mode toggle
  Widget _buildGuestHeader(bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // Mode toggle buttons
          Row(
            children: [
              _buildHeaderModeButton(
                isDarkMode: isDarkMode,
                icon: Icons.auto_awesome,
                label: localizations.ai_mode_label,
                isSelected: !_isSearchMode,
                onTap: () {}, // Already in AI mode
              ),
              const SizedBox(width: 8),
              _buildHeaderModeButton(
                isDarkMode: isDarkMode,
                icon: Icons.search,
                label: localizations.text_search,
                isSelected: _isSearchMode,
                onTap: () => setState(() => _isSearchMode = true),
              ),
            ],
          ),
          Text(
            localizations.ai_buddhist_assistant,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildHeaderModeButton({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode
                  ? AppColors.accentGold.withValues(alpha: 0.2)
                  : AppColors.accentGoldContainer)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.accentGold, width: 1.5)
              : Border.all(
                  color: isDarkMode ? AppColors.grey800 : AppColors.grey300,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.accentGold
                  : (isDarkMode ? AppColors.grey400 : AppColors.grey600),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.accentGold
                    : (isDarkMode ? AppColors.grey400 : AppColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isDarkMode, bool isGuest) {
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
          // Text input container
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppColors.surfaceVariantDark
                      : AppColors.accentGoldSurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Text field
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: false,
                  enableInteractiveSelection: true,
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText:
                        _isSearchMode
                            ? AppLocalizations.of(
                              context,
                            )!.search_buddhist_texts
                            : AppLocalizations.of(context)!.ai_ask_question,
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

                // Controls row with mode selection and send button
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 4,
                    bottom: 4,
                    top: 4,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      // Mode selection buttons (AI and Search)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // AI Mode Button
                          _buildCompactModeButton(
                            isDarkMode: isDarkMode,
                            icon: Icons.auto_awesome,
                            isSelected: !_isSearchMode,
                            onTap: () {
                              if (isGuest) {
                                // Show sign-in prompt for guests
                                LoginDrawer.show(context, ref);
                                return;
                              }
                              setState(() {
                                _isSearchMode = false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          // Search Mode Button
                          _buildCompactModeButton(
                            isDarkMode: isDarkMode,
                            icon: Icons.search,
                            isSelected: _isSearchMode,
                            onTap: () {
                              setState(() {
                                _isSearchMode = true;
                              });
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Send button
                      IconButton(
                        onPressed: canSend ? _onSendMessage : null,
                        icon: Icon(
                          Icons.send_rounded,
                          color:
                              canSend
                                  ? (isDarkMode
                                      ? AppColors.accentGoldContainer
                                      : AppColors.backgroundDark)
                                  : (isDarkMode
                                      ? AppColors.grey500
                                      : AppColors.grey800),
                          size: 22,
                        ),
                      ),
                    ],
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

  Widget _buildCompactModeButton({
    required bool isDarkMode,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDarkMode
                      ? AppColors.accentGold.withValues(alpha: 0.2)
                      : AppColors.accentGoldContainer)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(color: AppColors.accentGold, width: 1.5)
                  : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color:
              isSelected
                  ? AppColors.accentGold
                  : (isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary),
        ),
      ),
    );
  }
}
