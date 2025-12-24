import 'package:flutter_pecha/features/ai/models/chat_message.dart';

/// Represents a thread summary in the thread list
class ChatThreadSummary {
  final String id;
  final String title;

  ChatThreadSummary({
    required this.id,
    required this.title,
  });

  factory ChatThreadSummary.fromJson(Map<String, dynamic> json) {
    return ChatThreadSummary(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}

/// Represents a complete thread with all messages
class ChatThreadDetail {
  final String id;
  final String title;
  final List<ThreadMessage> messages; // ThreadMessage Class defined below.

  ChatThreadDetail({
    required this.id,
    required this.title,
    required this.messages,
  });

  factory ChatThreadDetail.fromJson(Map<String, dynamic> json) {
    final messagesData = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesData
        .map((m) => ThreadMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return ChatThreadDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  /// Convert to list of ChatMessage for display
  List<ChatMessage> toChatMessages() {
    return messages.map((m) => m.toChatMessage()).toList();
  }
}

/// Represents a message in a thread (API format)
class ThreadMessage {
  final String role; // "user" or "assistant"
  final String content;
  final String id;
  final List<SearchResult>? searchResults;

  ThreadMessage({
    required this.role,
    required this.content,
    required this.id,
    this.searchResults,
  });

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    final searchResultsData = json['searchResults'] as List<dynamic>?;
    final searchResults = searchResultsData
        ?.map((r) => SearchResult.fromJson(r as Map<String, dynamic>))
        .toList();

    return ThreadMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      id: json['id'] as String,
      searchResults: searchResults,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'id': id,
      if (searchResults != null)
        'searchResults': searchResults!.map((r) => {
          'id': r.id,
          'title': r.title,
          'text': r.text,
          'score': r.score,
          'distance': r.distance,
        }).toList(),
    };
  }

  /// Convert to ChatMessage for display
  ChatMessage toChatMessage() {
    return ChatMessage(
      content: content,
      isUser: role == 'user',
      searchResults: searchResults ?? [],
    );
  }
}

/// Response model for thread list API
class ThreadListResponse {
  final List<ChatThreadSummary> data;
  final int total;

  ThreadListResponse({
    required this.data,
    required this.total,
  });

  factory ThreadListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final threads = dataList
        .map((t) => ChatThreadSummary.fromJson(t as Map<String, dynamic>))
        .toList();

    return ThreadListResponse(
      data: threads,
      total: json['total'] as int? ?? 0,
    );
  }
}

