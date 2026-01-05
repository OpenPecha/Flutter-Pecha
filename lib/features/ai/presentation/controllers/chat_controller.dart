import 'dart:async';
import 'dart:math';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/ai/data/providers/ai_chat_provider.dart';
import 'package:flutter_pecha/features/ai/data/repositories/ai_chat_repository.dart';
import 'package:flutter_pecha/features/ai/models/chat_message.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/thread_list_controller.dart';
import 'package:flutter_pecha/features/auth/application/user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String currentStreamingContent;
  final List<SearchResult> currentSearchResults;
  final String? error;
  final String? currentThreadId;
  final bool isLoadingThread;

  ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.currentStreamingContent = '',
    this.currentSearchResults = const [],
    this.error,
    this.currentThreadId,
    this.isLoadingThread = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    String? currentStreamingContent,
    List<SearchResult>? currentSearchResults,
    String? error,
    String? currentThreadId,
    bool? isLoadingThread,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      currentStreamingContent: currentStreamingContent ?? this.currentStreamingContent,
      currentSearchResults: currentSearchResults ?? this.currentSearchResults,
      error: error,
      currentThreadId: currentThreadId ?? this.currentThreadId,
      isLoadingThread: isLoadingThread ?? this.isLoadingThread,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final AiChatRepository _repository;
  final Ref _ref;
  final _logger = AppLogger('ChatController');
  StreamSubscription? _streamSubscription;

  ChatController(this._repository, this._ref) : super(ChatState());

  /// Get user email or generate a random guest email
  String _getUserEmail() {
    final userState = _ref.read(userProvider);
    
    // Check if user is authenticated and has an email
    if (userState.isAuthenticated && 
        userState.user?.email != null && 
        userState.user!.email!.isNotEmpty) {
      _logger.debug('Using authenticated user email: ${userState.user!.email}');
      return userState.user!.email!;
    }
    
    // Otherwise, use guest email
    _logger.debug('User not authenticated or no email, using random generated guest email');
    return _generateGuestEmail();
  }
  
  /// Generate a random guest email for unauthenticated users
  String _generateGuestEmail() {
    final random = Random();
    final randomId = random.nextInt(999999).toString().padLeft(6, '0');
    return 'guest_$randomId@temp.com';
  }

  /// Sends a message to the AI and handles the streaming response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Cancel any ongoing stream
    await _streamSubscription?.cancel();

    // Add user message to the list
    final userMessage = ChatMessage(content: content, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      error: null,
    );

    // Get user email
    final email = _getUserEmail();
    
    // Log the thread_id being sent (or null if new conversation)
    if (state.currentThreadId != null) {
      _logger.info('Sending message with existing thread_id: ${state.currentThreadId}');
    } else {
      _logger.info('Sending message for new conversation (no thread_id)');
    }

    // Start streaming AI response
    state = state.copyWith(
      isStreaming: true,
      currentStreamingContent: '',
      currentSearchResults: [],
    );

    try {
      final stream = _repository.sendMessage(
        message: content,
        email: email,
        threadId: state.currentThreadId,
      );
      
      _streamSubscription = stream.listen(
        (event) {
          if (event is SearchResultsEvent) {
            // Store search results for citations
            _logger.debug('Received search results: ${event.results.length} items');
            state = state.copyWith(
              currentSearchResults: event.results,
            );
          } else if (event is TokenEvent) {
            // Append token to the streaming content
            state = state.copyWith(
              currentStreamingContent: state.currentStreamingContent + event.token,
            );
          } else if (event is ThreadIdEvent) {
            // Store the thread_id for subsequent messages
            _logger.info('Received and stored thread_id: ${event.threadId}');
            state = state.copyWith(
              currentThreadId: event.threadId,
            );
            // Refresh threads list when we get a new thread_id (new conversation)
            _ref.read(threadListControllerProvider.notifier).refreshThreads();
          } else if (event is DoneEvent) {
            // Finalize the AI message with search results
            final aiMessage = ChatMessage(
              content: state.currentStreamingContent,
              isUser: false,
              searchResults: state.currentSearchResults,
            );
            state = state.copyWith(
              messages: [...state.messages, aiMessage],
              isStreaming: false,
              currentStreamingContent: '',
              currentSearchResults: [],
            );
            _logger.info('Message streaming completed');
          } else if (event is ErrorEvent) {
            _logger.error('Stream error: ${event.message}');
            state = state.copyWith(
              isStreaming: false,
              currentStreamingContent: '',
              currentSearchResults: [],
              error: event.message,
            );
          }
        },
        onError: (error, stackTrace) {
          _logger.error('Stream subscription error', error, stackTrace);
          state = state.copyWith(
            isStreaming: false,
            currentStreamingContent: '',
            error: error.toString(),
          );
        },
        onDone: () {
          _logger.info('Stream subscription completed');
        },
      );
    } catch (e, stackTrace) {
      _logger.error('Error sending message', e, stackTrace);
      state = state.copyWith(
        isStreaming: false,
        currentStreamingContent: '',
        error: e.toString(),
      );
    }
  }

  /// Load a thread by ID
  Future<void> loadThread(String threadId) async {
    _logger.info('Loading thread: $threadId');
    
    try {
      // Cancel any ongoing stream
      await _streamSubscription?.cancel();
      
      // Set loading state
      state = state.copyWith(
        isStreaming: false,
        currentStreamingContent: '',
        error: null,
        isLoadingThread: true,
      );

      // Fetch thread details
      final thread = await _repository.getThreadById(threadId);
      
      // Convert thread messages to chat messages
      final chatMessages = thread.toChatMessages();
      
      // Update state with loaded messages
      state = state.copyWith(
        messages: chatMessages,
        currentThreadId: threadId,
        isLoadingThread: false,
      );
      
      _logger.info('Loaded thread with ${chatMessages.length} messages');
    } catch (e, stackTrace) {
      _logger.error('Error loading thread', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to load conversation: ${e.toString()}',
        isLoadingThread: false,
      );
    }
  }

  /// Start a new thread (clear current conversation)
  void startNewThread() {
    _logger.info('Starting new thread');
    
    // Cancel any ongoing stream
    _streamSubscription?.cancel();
    
    // Clear all state
    state = ChatState();
  }

  /// Clears the error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final repository = ref.watch(aiChatRepositoryProvider);
  return ChatController(repository, ref);
});

