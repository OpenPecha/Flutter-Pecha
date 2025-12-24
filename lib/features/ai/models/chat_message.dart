class SearchResult {
  final String id;
  final String title;
  final String text;
  final double score;
  final double distance;

  SearchResult({
    required this.id,
    required this.title,
    required this.text,
    required this.score,
    required this.distance,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      text: json['text'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<SearchResult> searchResults;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.searchResults = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<SearchResult>? searchResults,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

