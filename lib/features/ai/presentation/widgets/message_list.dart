import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/ai/models/chat_message.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/message_bubble.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/typing_indicator.dart';

class MessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final String currentStreamingContent;

  const MessageList({
    super.key,
    required this.messages,
    required this.isStreaming,
    required this.currentStreamingContent,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to bottom when new messages arrive or streaming updates
    if (widget.messages.length != oldWidget.messages.length ||
        widget.currentStreamingContent != oldWidget.currentStreamingContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: widget.messages.length + (widget.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < widget.messages.length) {
          // Display regular message
          return MessageBubble(message: widget.messages[index]);
        } else {
          // Display typing indicator or streaming content
          return TypingIndicator(
            currentContent: widget.currentStreamingContent,
          );
        }
      },
    );
  }
}
